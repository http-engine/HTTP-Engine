package HTTP::Engine::Interface;
use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_caller => [ 'builder', 'writer', '__INTERFACE__'],
    also        => 'Moose',
);

my $WRITER;

sub builder {
    my ($caller, $builder ) = @_;
    $builder = ($builder =~ s/^\+(.+)$//) ? $1 : "HTTP::Engine::RequestBuilder::$builder";
    Class::MOP::load_class($builder);
    my $instance = $builder->new;
    $caller->meta->add_method(
        'request_builder' => sub { $instance }
    );
}

sub writer {
    my ($caller, $args) = @_;

    $WRITER->{$caller} = $args;
}

# fix up Interface.
sub __INTERFACE__ {
    my ($caller, ) = @_;

    if (my $args = delete $WRITER->{$caller}) {
        my $writer = _construct_writer($args)->new_object->new;
        $caller->meta->make_mutable;
        $caller->meta->add_method(
            'response_writer' => sub {
                $writer;
            }
        );
    }

    Moose::Util::apply_all_roles($caller, 'HTTP::Engine::Role::Interface');

    $caller->meta->make_immutable;
}

sub _construct_writer {
    my ($args, ) = @_;

    my $writer = Moose::Meta::Class->create_anon_class(
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
