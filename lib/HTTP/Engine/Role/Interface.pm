package HTTP::Engine::Role::Interface;
use strict;
use warnings;
use HTTP::Engine::Role;

requires run => ['Method'];
requires_with_attributes ['InterfaceMethod'], qw(
    prepare_connection       
    prepare_query_parameters 
    prepare_headers          
    prepare_cookie           
    prepare_path             
    prepare_body             
    prepare_body_parameters  
    prepare_parameters       
    prepare_uploads          
    finalize_cookies         
    finalize_output_headers  
    finalize_output_body     
);


1;
