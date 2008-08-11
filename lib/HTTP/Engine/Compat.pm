package HTTP::Engine::Compat;
use Moose;
extends 'HTTP::Engine';
use HTTP::Engine::RequestProcessor;
use HTTP::Engine::Request;
use HTTP::Engine::Compat::Context;

sub import {
    my($class, %args) = @_;

    $class->_wrap( \&_extract_context );

    $class->_modify(
        'HTTP::Engine::Request',
        sub {
            my $meta = shift;
            $meta->add_attribute(
                context => {
                    is       => 'rw',
                    isa      => 'HTTP::Engine::Compat::Context',
                    weak_ref => 1,
                }
            );
        }
    );

    $class->_modify(
        'HTTP::Engine::Response',
        sub {
            my $meta = shift;
            $meta->add_attribute(
                location => {
                    is  => 'rw',
                    isa => 'Str',
                }
            );
            $meta->add_method(
                redirect => sub {
                    my $self = shift;

                    if (@_) {
                        $self->location( shift );
                        $self->status( shift || 302 );
                    }

                    $self->location;
                }
            );
        }
    );

    $class->_modify(
        'HTTP::Engine::ResponseFinalizer',
        sub {
            my $meta = shift;
            $meta->add_around_method_modifier(
                finalize => sub {
                    my ($code, $self, $req, $res) = @_;
                    if (my $location = $res->location) {
                        $res->header( Location => $req->absolute_url($location) );
                        $res->body($res->status . ': Redirect') unless $res->body;
                    }
                    $code->($self, $req, $res);
                },
            )
        }
    );

    return unless $args{middlewares} && ref $args{middlewares} eq 'ARRAY';
    $class->load_middlewares(@{ $args{middlewares} });
}

sub load_middlewares {
    my ($class, @middlewares) = @_;
    for my $middleware (@middlewares) {
        $class->load_middleware( $middleware );
    }
}

sub load_middleware {
    my ($class, $middleware) = @_;

    my $pkg;
    if (($pkg = $middleware) =~ s/^(\+)//) {
        Class::MOP::load_class($pkg) or die $@;
    } else {
        $pkg = 'HTTP::Engine::Middleware::' . $middleware;
        unless (eval { Class::MOP::load_class($pkg) }) {
            $pkg = 'HTTPEx::Middleware::' . $middleware;
            Class::MOP::load_class($pkg);
        }
    }

    if ($pkg->meta->has_method('setup')) {
        $pkg->setup();
    }

    if ($pkg->meta->has_method('wrap')) {
        $class->_wrap( $pkg->meta->get_method('wrap')->body );
        $class->_wrap( \&_extract_context );
    }
}

sub _wrap {
    my ($class, $code ) = @_;
    $class->_modify(
        'HTTP::Engine::RequestProcessor',
        sub {
            my $meta = shift;
            $meta->add_around_method_modifier(
                call_handler => $code,
            );
        },
    );
}

sub _extract_context {
    my ($code, $arg) = @_;

    # process argument
    if (Scalar::Util::blessed($arg) ne 'HTTP::Engine::Compat::Context') {
        $arg = HTTP::Engine::Compat::Context->new(
            req => $arg,
            res => HTTP::Engine::Response->new(
                status => 200
            ),
        );
    }

    my $ret = $code->($arg);

    # process return value
    my $res;
    if (Scalar::Util::blessed($ret) && $ret->isa('HTTP::Engine::Response')) {
        $res = $ret;
    } else {
        $res = $arg->res;
    }

    return $res;
}

sub _modify {
    my ($class, $target, $cb) = @_;
    my $meta = $target->meta;
    $meta->make_mutable;
    $cb->($meta);
    $meta->make_immutable;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
