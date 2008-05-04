package HTTP::Engine::Plugin::Interface::Adaptor;
use strict;
use warnings;
use base 'HTTP::Engine::Plugin::Interface';

__PACKAGE__->mk_accessors(qw/ adaptee /);

sub set_adaptee :Method {
    my($self, $c, $adaptee) = @_;
    $self->adaptee($adaptee);
}

sub run { $_[0]->adaptee->run(@_) }

sub prepare_request { $_[0]->adaptee->prepare_request(@_) }
sub prepare_connection { $_[0]->adaptee->prepare_connection(@_) }
sub prepare_query_parameters { $_[0]->adaptee->prepare_query_parameters(@_) }
sub prepare_headers { $_[0]->adaptee->prepare_headers(@_) }
sub prepare_cookie { $_[0]->adaptee->prepare_cookie(@_) }
sub prepare_path { $_[0]->adaptee->prepare_path(@_) }
sub prepare_body { $_[0]->adaptee->prepare_body(@_) }
sub prepare_body_parameters { $_[0]->adaptee->prepare_body_parameters(@_) }
sub prepare_parameters { $_[0]->adaptee->prepare_parameters(@_) }
sub prepare_uploads { $_[0]->adaptee->prepare_uploads(@_) }

sub finalize_cookies { $_[0]->adaptee->finalize_cookies(@_) }
sub finalize_output_headers { $_[0]->adaptee->finalize_output_headers(@_) }
sub finalize_output_body { $_[0]->adaptee->finalize_output_body(@_) }

1;

