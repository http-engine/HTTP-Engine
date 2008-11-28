package HTTP::Engine::Util;
use strict;
use warnings;

{
    my $required;
    sub require_once {
        my $pkg = shift;
        return if $required->{$pkg};
        require $pkg;
        $required->{$pkg}++;
    }
}

1;
