package HTTP::Engine::Interface::POE::Filter;
use Moose;
extends 'POE::Filter::HTTPD';

# omit output filter
sub put {
    shift; # class name
    return @_;
}

1;
