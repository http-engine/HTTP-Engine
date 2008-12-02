package HTTP::Engine::Interface;
use Mouse;
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

    my $meta = Mouse::Meta::Class->initialize($caller);
    $meta->superclasses('Mouse::Object')
      unless $meta->superclasses;

    no strict 'refs';
    no warnings 'redefine';
    *{ $caller . '::meta' } = sub { $meta };

    Mouse->export_to_level( 1, @_ );
}

# fix up Interface.
sub __INTERFACE__ {
    my ($caller, ) = @_;

    my %args = %{ delete $ARGS->{$caller} };

    my $builder = delete $args{builder} or die "missing builder";
    my $writer  = delete $args{writer}  or die "missing writer";

    _setup_builder($caller, $builder);
    _setup_writer($caller,  $writer);

    Mouse::apply_roles($caller, 'HTTP::Engine::Role::Interface');

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

    my $writer = _construct_writer($caller, $args)->new;
    no strict 'refs';
    *{"$caller\::response_writer"} = sub { $writer };
}

sub _construct_writer {
    my ($caller, $args, ) = @_;

    my $writer = $caller . '::ResponseWriter';
    Mouse::init_class($writer);

    {
        no strict 'refs';

        my @roles;
        my $apply = sub { push @roles, "HTTP::Engine::Role::ResponseWriter::$_[0]" };
        if ($args->{finalize}) {
            *{"$writer\::finalize"} = $args->{finalize};
        } else {
            if ($args->{response_line}) {
                $apply->('ResponseLine');
            }
            if (my $code = $args->{output_body}) {
                *{"$writer\::output_body"} = $code;
            } else {
                $apply->('OutputBody');
            }
            if (my $code = $args->{write}) {
                *{"$writer\::write"} = $code;
            } else {
                $apply->('WriteSTDOUT');
            }
            $apply->('Finalize');
        }
        Mouse::apply_roles($writer, @roles, "HTTP::Engine::Role::ResponseWriter");
    }

    for my $before (keys %{ $args->{before} || {} }) {
        Mouse::add_before_method_modifier( $writer, $before => $args->{before}->{$before} );
    }
    for my $attribute (keys %{ $args->{attributes} || {} }) {
        Mouse::add_attribute( $writer, $attribute, $args->{attributes}->{$attribute} );
    }

    return $writer;
}

1;
