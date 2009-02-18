use strict;
use warnings;
use Test::More tests => 1;

use File::Spec;
use File::Path;

rmtree(File::Spec->catfile(qw/ t moose /));
ok 1;
