package HTTP::Engine::Interface;
use Moose;
use Moose::Exporter;
use HTTP::Engine::ResponseWriter;

Moose::Exporter->setup_import_methods(
    with_caller => [ 'builder', 'writer', '__INTERFACE__'],
    also        => 'Moose',
);

my $WRITER;

sub builder {
    my ($caller, $builder ) = @_;
    $builder = ($builder =~ s/^\+(.+)$//) ? $1 : "HTTP::Engine::RequestBuilder::$builder";
    Class::MOP::load_class($builder);
    $caller->meta->add_method(
        '_build_request_builder' => sub { $builder->new }
    );
}

sub writer {
    my ($caller, $args) = @_;

    $WRITER->{$caller} = $args;
}

sub __INTERFACE__ {
    my ($caller, ) = @_;

    # setup writer
    if (my $args = $WRITER->{$caller}) {
        my $writer = Moose::Meta::Class->create_anon_class(
            superclasses => ['HTTP::Engine::ResponseWriter'],
            roles => [
                map( {"HTTP::Engine::Role::ResponseWriter::$_"}
                    @{ $args->{roles} || [] } ),
                'HTTP::Engine::Role::ResponseWriter',
            ],
            ( $args->{methods} ? (methods => $args->{methods}) : () ),
            cache => 1,
        );
        for my $attribute (keys %{ $args->{attributes} || {} }) {
            $writer->add_attribute( $attribute => $args->{attributes}->{$attribute} );
        }
        for my $before (keys %{ $args->{before} || {} }) {
            $writer->add_before_method_modifier( $before => $args->{before}->{$before} );
        }
        $caller->meta->add_method(
            '_build_response_writer' => sub {
                $writer->new_object->new
            }
        );
    };

    Moose::Util::apply_all_roles($caller, 'HTTP::Engine::Role::Interface');

    $caller->meta->make_immutable;
}

1;
