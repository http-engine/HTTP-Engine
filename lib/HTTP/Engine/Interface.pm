package HTTP::Engine::Interface;
use Moose;

*unimport = *Moose::unimport;

my $ARGS = {};

sub import {
    my $class = shift;

    my $caller  = caller(0);
    $ARGS->{$caller} = {@_};

    no strict 'refs';
    *{"$caller\::__INTERFACE__"} = sub {
        my $caller = caller(0);
        __INTERFACE__($caller);
    };

    strict->import;
    warnings->import;

    return if $caller eq 'main';

    Moose::init_meta($caller);
    Moose->import( { into => $caller } );
}

# fix up Interface.
sub __INTERFACE__ {
    my ($caller, ) = @_;

    my %args = %{ delete $ARGS->{$caller} };

    my $builder = delete $args{builder} or die "missing builder";
    my $writer  = delete $args{writer}  or die "missing writer";

    _setup_builder($caller, $builder);
    _setup_writer($caller,  $writer);

    Moose::Util::apply_all_roles($caller, 'HTTP::Engine::Role::Interface');
    $caller->meta->make_immutable;
}

sub _setup_builder {
    my ($caller, $builder ) = @_;
    $builder = ($builder =~ s/^\+(.+)$//) ? $1 : "HTTP::Engine::RequestBuilder::$builder";
    Class::MOP::load_class($builder);
    my $instance = $builder->new;
    $caller->meta->add_method(
        'request_builder' => sub { $instance }
    );
}

sub _setup_writer {
    my ($caller, $args) = @_;

    my $writer = _construct_writer($caller, $args)->new_object->new;
    $caller->meta->add_method(
        'response_writer' => sub {
            $writer;
        }
    );
}

sub _construct_writer {
    my ($caller, $args, ) = @_;

    my $writer = Moose::Meta::Class->create( $caller . '::ResponseWriter',
        superclasses => ['Moose::Object'],
        cache => 1,
    );

    {
        my @roles;
        my $apply = sub { push @roles, "HTTP::Engine::Role::ResponseWriter::$_[0]" };
        if ($args->{finalize}) {
            $writer->add_method(finalize => $args->{finalize});
        } else {
            if ($args->{response_line}) {
                $apply->('ResponseLine');
            }
            if (my $code = $args->{output_body}) {
                $writer->add_method('output_body' => $code);
            } else {
                $apply->('OutputBody');
            }
            if (my $code = $args->{write}) {
                $writer->add_method('write' => $code);
            } else {
                $apply->('WriteSTDOUT');
            }
            $apply->('Finalize');
        }
        Moose::Util::apply_all_roles($writer, @roles, "HTTP::Engine::Role::ResponseWriter");
    }

    for my $before (keys %{ $args->{before} || {} }) {
        $writer->add_before_method_modifier( $before => $args->{before}->{$before} );
    }
    for my $attribute (keys %{ $args->{attributes} || {} }) {
        $writer->add_attribute( $attribute => $args->{attributes}->{$attribute} );
    }

    $writer->make_immutable;

    return $writer;
}

1;
