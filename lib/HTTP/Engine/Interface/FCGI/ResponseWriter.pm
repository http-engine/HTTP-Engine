package HTTP::Engine::Interface::FCGI::ResponseWriter;
use Moose::Role;

with qw(
    HTTP::Engine::Role::ResponseWriter
    HTTP::Engine::Role::ResponseWriter::ResponseLine
    HTTP::Engine::Role::ResponseWriter::OutputBody
);

# XXX: We can't use Engine's write() method because syswrite
# appears to return bogus values instead of the number of bytes
# written: http://www.fastcgi.com/om_archive/mail-archive/0128.html

# FastCGI does not stream data properly if using 'print $handle',
# but a syswrite appears to work properly.

sub write {
    my ($self, $buffer) = @_;

    *STDOUT->syswrite($buffer);
}

1;
