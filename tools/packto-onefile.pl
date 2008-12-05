use strict;
use warnings;
use lib 'lib';
use Path::Class;
use File::Slurp;
use PPI;
use Perl6::Say;
use HTTP::Engine;
use HTTP::Engine::Interface::CGI;
use UNIVERSAL::require;

my $PATH_TO_MOUSE_TINY = shift or die "Usage: $0 ../Mouse/lib/Mouse/Tiny.pm";

my @files = qw(
    HTTP/Engine/Util.pm
    HTTP/Engine/Types/Core.pm
    HTTP/Engine/Request.pm
    HTTP/Engine.pm
    HTTP/Engine/Role/Interface.pm
    HTTP/Engine/ResponseFinalizer.pm
    HTTP/Engine/Request/Upload.pm
    HTTP/Engine/Response.pm
    HTTP/Engine/Role/RequestBuilder/ReadBody.pm
    HTTP/Engine/Role/RequestBuilder/HTTPBody.pm
    HTTP/Engine/Role/RequestBuilder/ParseEnv.pm
    HTTP/Engine/Role/RequestBuilder/Standard.pm
    HTTP/Engine/Role/RequestBuilder.pm
    HTTP/Engine/RequestBuilder/CGI.pm
    HTTP/Engine/Role/ResponseWriter/OutputBody.pm
    HTTP/Engine/Role/ResponseWriter.pm
    HTTP/Engine/Role/ResponseWriter/Finalize.pm
    HTTP/Engine/Role/ResponseWriter/ResponseLine.pm
    HTTP/Engine/Role/ResponseWriter/WriteSTDOUT.pm
    HTTP/Engine/Interface.pm
    HTTP/Engine/Interface/CGI.pm
);

# Mouse::Tiny
sub {
    my $src = join '', read_file($PATH_TO_MOUSE_TINY);
    say $src;
}->();

# header
for (@files) {
    say "\$INC{'$_'} = __FILE__;";
}

# http::engine
for my $file (@files) {
    my $src = join '', read_file("lib/$file");
    my $doc = PPI::Document->new(\$src);
    $doc->prune('PPI::Token::Pod');
    $doc->prune('PPI::Token::Comment');
    $doc->find(
        sub {
            if ($_[1]->isa('PPI::Statement::Include')) {
                if ($_[1]->module =~ /^HTTP::Engine/) {
                    eval {
                        my $content = $_[1]->content;
                        if ($content =~ /^use\s*(HTTP::Engine\S+)\s*(.*?);$/ms) {
                            my ($pkg, $args) = ($1, $2);
                            if ($pkg->can('import') && $pkg !~ /HTTP::Engine::(Util|Response|Request)/) {
                                my $token = PPI::Token::Word->new("BEGIN { ${pkg}::import('${pkg}', $args); }\n");
                                $_[0]->__replace_child($_[1], $token);
                            } else {
                                $_[1]->delete;
                            }
                        } else {
                            warn "WTF? $content";
                        }
                    };
                    warn $@ if $@;
                }
            }
            return;
        }
    );
    my $content = $doc->serialize;
    $content =~ s/^__END__$//smg;
    say "{\n$content\n}\n";
}

__END__
