package HTTP::Engine::Context;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/ req res handle_error_message /);

*request  = \&req;
*response = \&res;

1;

