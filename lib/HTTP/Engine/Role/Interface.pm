package HTTP::Engine::Role::Interface;
use strict;
use warnings;
use HTTP::Engine::Plugin;

requires run => 'Method';
requires
    prepare_connection       => 'InterfaceMethod',
    prepare_query_parameters => 'InterfaceMethod',
    prepare_headers          => 'InterfaceMethod',
    prepare_cookie           => 'InterfaceMethod',
    prepare_path             => 'InterfaceMethod',
    prepare_body             => 'InterfaceMethod',
    prepare_body_parameters  => 'InterfaceMethod',
    prepare_parameters       => 'InterfaceMethod',
    prepare_uploads          => 'InterfaceMethod',
    finalize_cookies         => 'InterfaceMethod',
    finalize_output_headers  => 'InterfaceMethod',
    finalize_output_body     => 'InterfaceMethod',
;


1;
