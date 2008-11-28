package HTTP::Engine::ClassCreator;
use strict;
use warnings;

my $CLASSID = 0;

sub create_anon {
    my ($class, %args) = @_;
    my $name = "HTTP::Engine::ClassCreator::AnonClass$CLASSID";
    $class->create($name, %args);
}

sub create {
    my ($class, $name, %args) = @_;
    no strict 'refs';
    if (my $super = $args{superclasses}) {
        $super = [$super] unless ref $super;
        for my $klass (@$super) {
            unshift @{"$name\::ISA"}, $klass;
        }
    }
    if (my $methods = $args{methods}) {
        while (my ($meth, $code) = each %$methods) {
            *{"$name\::$meth"} = $code;
        }
    }
    return $name;
}

1;
