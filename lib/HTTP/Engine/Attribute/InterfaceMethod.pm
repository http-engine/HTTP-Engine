package HTTP::Engine::Attribute::InterfaceMethod;
use strict;
use warnings;
use base 'Class::Component::Attribute';

sub register {
    my($class, $plugin, $c, $method, $value) = @_;

    $c->register_method( $method => $plugin );
    my $pkg = ref($c) || $c;
    no strict 'refs';
    no warnings 'redefine';
    *{"$pkg\::$method"} = sub {
        my $self = shift;
        my $c    = shift;
        $c->run_hook( "before_$method", $c, @_ );
        my @ret = $plugin->$method($c, @_);
        $c->run_hook( "after_$method", $c, @_ );
        @ret;
    };
}

1;
