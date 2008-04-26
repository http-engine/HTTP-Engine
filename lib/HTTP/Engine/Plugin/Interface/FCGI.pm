package HTTP::Engine::Plugin::Interface::FCGI;
use strict;
use warnings;
require HTTP::Engine::Plugin::Interface;
use base 'HTTP::Engine::Plugin::Interface';
use HTTP::Status;
use FCGI;

sub run :Method {
    my ( $self, $class, $listen, ) = @_;

    my $options = $self->conf;

    my $sock = 0;
    if ($listen) {
        my $old_umask = umask;
        unless ( $options->{leave_umask} ) {
            umask(0);
        }
        $sock = FCGI::OpenSocket( $listen, 100 )
          or die "failed to open FastCGI socket; $!";
        unless ( $options->{leave_umask} ) {
            umask($old_umask);
        }
    }
    elsif ( $^O ne 'MSWin32' ) {
        -S STDIN
          or die "STDIN is not a socket; specify a listen location";
    }

    $options ||= {};

    my %env;
    my $error = \*STDERR;    # send STDERR to the web server
    $error = \*STDOUT                # send STDERR to stdout (a logfile)
      if $options->{keep_stderr};    # (if asked to)

    my $request =
      FCGI::Request( \*STDIN, \*STDOUT, $error, \%env, $sock,
        ( $options->{nointr} ? 0 : &FCGI::FAIL_ACCEPT_ON_INTR ),
      );

    my $proc_manager;

    if ($listen) {
        $options->{manager} ||= "FCGI::ProcManager";
        $options->{nproc}   ||= 1;

        $self->daemon_fork() if $options->{detach};

        if ( $options->{manager} ) {
            eval "use $options->{manager}; 1" or die $@;

            $proc_manager = $options->{manager}->new(
                {
                    n_processes => $options->{nproc},
                    pid_fname   => $options->{pidfile},
                }
            );

            # detach *before* the ProcManager inits
            $self->daemon_detach() if $options->{detach};

            $proc_manager->pm_manage();
        }
        elsif ( $options->{detach} ) {
            $self->daemon_detach();
        }
    }

    while ( $request->Accept >= 0 ) {
        $proc_manager && $proc_manager->pm_pre_dispatch();

        # If we're running under Lighttpd, swap PATH_INFO and SCRIPT_NAME
        # http://lists.rawmode.org/pipermail/catalyst/2006-June/008361.html
        # Thanks to Mark Blythe for this fix
        if ( $env{SERVER_SOFTWARE} && $env{SERVER_SOFTWARE} =~ /lighttpd/ ) {
            $env{PATH_INFO} ||= delete $env{SCRIPT_NAME};
        }

        local %ENV = %env;
        $class->handle_request();

        $proc_manager && $proc_manager->pm_post_dispatch();
    }
}

sub write {
    my($self, $buffer) = @_;

    unless ( $self->{_prepared_write} ) {
        $self->prepare_write;
        $self->{_prepared_write} = 1;
    }

    # XXX: We can't use Engine's write() method because syswrite
    # appears to return bogus values instead of the number of bytes
    # written: http://www.fastcgi.com/om_archive/mail-archive/0128.html

    # FastCGI does not stream data properly if using 'print $handle',
    # but a syswrite appears to work properly.
    *STDOUT->syswrite($buffer);
}

sub daemon_fork {
    require POSIX;
    fork && exit;
}

sub daemon_detach {
    my $self = shift;
    print "FastCGI daemon started (pid $$)\n";
    open STDIN,  "+</dev/null" or die $!;
    open STDOUT, ">&STDIN"     or die $!;
    open STDERR, ">&STDIN"     or die $!;
    POSIX::setsid();
}

1;
__END__

=head1 SYNOPSIS

    - module: Interface::FCGI
      conf:
        leave_umask: 1

=head1 AUTHORS

Tokuhiro Matsuno

=head1 THANKS TO

may codes copied from L<Catalyst::Engine::FastCGI>. thanks authors of C::E::FastCGI!

