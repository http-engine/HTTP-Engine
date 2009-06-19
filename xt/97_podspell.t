use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kazuhiro Osawa
HTTP::Engine
FastCGI
HTTPEx
PLUGINS
namespace
plugins
COMMITTERS
adaptor
lestrrat
tokuhirom
Tokuhiro
Matsuno
marcus
nyarla
wiki
Coro
preforking
yaml
CGI
Daisuke
Maki
STDOUT
TODO
XXX
dann
handler's
hidek
webapp
typester
lopnor
filename
TCP
pre
pm
kawa
walf
shibuya
mattn
AnyEvent
Async
HowTo
Stosberg
implemens
namespaces
newbies
gugod
stevan
overridable
fujiwara
hirose31
GitHub
XXX
xxx
miyagawa
