package HTTP::Engine::Interface;
use Shika;
use UNIVERSAL::require;

my $ARGS = {};

sub import {
    my $class = shift;

    my $caller  = caller(0);
    return if $caller eq 'main';

    $ARGS->{$caller} = {@_};

    no strict 'refs';
    *{"$caller\::__INTERFACE__"} = sub {
        my $caller = caller(0);
        __INTERFACE__($caller);
    };

    strict->import;
    warnings->import;

    Shika::init_class($caller);
}

# fix up Interface.
sub __INTERFACE__ {
    my ($caller, ) = @_;

    my %args = %{ delete $ARGS->{$caller} };

    my $builder = delete $args{builder} or die "missing builder";
    my $writer  = delete $args{writer}  or die "missing writer";

    _setup_builder($caller, $builder);
    _setup_writer($caller,  $writer);

    Shika::apply_roles($caller, 'HTTP::Engine::Role::Interface');

    "END_OF_MODULE";
}

sub _setup_builder {
    my ($caller, $builder ) = @_;
    $builder = ($builder =~ s/^\+(.+)$//) ? $1 : "HTTP::Engine::RequestBuilder::$builder";
    unless ($builder->can('meta')) {
        $builder->require or die $@;
    }
    my $instance = $builder->new;

    no strict 'refs';
    *{"$caller\::request_builder"} = sub { $instance };
}

sub _setup_writer {
    my ($caller, $args) = @_;

    my $writer = _construct_writer($caller, $args)->new_object->new;
    no strict 'refs';
    *{"$caller\::response_writer"} = sub { $writer };
}

sub _construct_writer {
    my ($caller, $args, ) = @_;
    require Moose;

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

    return $writer;
}

1;
