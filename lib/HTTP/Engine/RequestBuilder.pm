package HTTP::Engine::RequestBuilder;
use Moose;
use CGI::Simple::Cookie;

with qw(
    HTTP::Engine::Role::RequestBuilder::ParseEnv
    HTTP::Engine::Role::RequestBuilder::HTTPBody
);

no Moose;

1;
__END__

=encoding utf8

=head1 NAME

HTTP::Engine::RequestBuilder - build request object from env/stdin

=head1 SYNOPSIS

    INTERNAL USE ONLY ＞＜

=head1 METHODS

=over 4

=item prepare

internal use only

=back

=head1 SEE ALSO

L<HTTP::Engine>

