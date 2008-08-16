package HTTP::Engine::Interface::FCGI::ResponseWriter;
use Moose::Role;

# XXX: We can't use Engine's write() method because syswrite
# appears to return bogus values instead of the number of bytes
# written: http://www.fastcgi.com/om_archive/mail-archive/0128.html

# FastCGI does not stream data properly if using 'print $handle',
# but a syswrite appears to work properly.

override _write => sub {
    my ($self, $buffer) = @_;

    *STDOUT->syswrite($buffer);
};

1;
