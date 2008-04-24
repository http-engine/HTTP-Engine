package HTTP::Engine::Plugin::Interface::Adaptor;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin::Interface';

use UNIVERSAL::require;

__PACKAGE__->mk_accessors(qw/ adaptee /);

sub init {
    my($self, $c) = @_;
    $self->config->{class}->require or die $@;
    $self->adaptee( $self->config->{class}->new( $self->config->{args} || {} ) );
}

sub run : Method { $_[0]->adaptee->run(@_) }

sub prepare_request : InterfaceMethod { $_[0]->adaptee->prepare_request(@_) }
sub prepare_connection : InterfaceMethod { $_[0]->adaptee->prepare_connection(@_) }
sub prepare_query_parameters : InterfaceMethod { $_[0]->adaptee->prepare_query_parameters(@_) }
sub prepare_headers : InterfaceMethod { $_[0]->adaptee->prepare_headers(@_) }
sub prepare_cookie : InterfaceMethod { $_[0]->adaptee->prepare_cookie(@_) }
sub prepare_path : InterfaceMethod { $_[0]->adaptee->prepare_path(@_) }
sub prepare_body : InterfaceMethod { $_[0]->adaptee->prepare_body(@_) }
sub prepare_body_parameters : InterfaceMethod { $_[0]->adaptee->prepare_body_parameters(@_) }
sub prepare_parameters : InterfaceMethod { $_[0]->adaptee->prepare_parameters(@_) }
sub prepare_uploads : InterfaceMethod { $_[0]->adaptee->prepare_upload(@_) }

sub finalize_cookies : InterfaceMethod { $_[0]->adaptee->finalize_cookies(@_) }
sub finalize_output_headers : InterfaceMethod { $_[0]->adaptee->finalize_output_headers(@_) }
sub finalize_output_body : InterfaceMethod { $_[0]->adaptee->finalize_output_body(@_) }

1;

