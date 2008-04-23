package HTTP::Engine::Context;

use strict;
use warnings;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw/ env engine req res conf /);

*request  = \&req;
*response = \&res;

1;

