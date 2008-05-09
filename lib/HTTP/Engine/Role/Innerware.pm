package HTTP::Engine::Role::Innerware;
use strict;
use warnings;
use HTTP::Engine::Role;
use base 'HTTP::Engine::Role';

requires before_hook => [{ Hook => 'innerware_before' }];
requires after_hook => [{ Hook => 'innerware_after' }];

1;
