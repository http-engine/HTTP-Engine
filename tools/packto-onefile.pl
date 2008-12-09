# -------------------------------------------------------------------------
# In the Moose world.
# making attribute is too slow.
# I want to preprocess it.
# THIS IS PROOF OF CONCEPT!!!!!
# -------------------------------------------------------------------------
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
use Data::Dumper;

die "this script is its in alpha quality!do not use this script without tokuhirom!" unless $ENV{USER} ne 'tokuhirom';

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

&main; exit;

sub process_accessor {
    my ($name, $klass, $attr) = @_;

    my $self  = '$_[0]';
    my $key   = $name;
    $name =~ s/^['"]//;
    $name =~ s/['"]$//;

    my $accessor = "{# attribute for $name\n";
    if ($attr->{trigger}) {
        $accessor .= "my \$trigger = $attr->{trigger};\n";
    }
    my $isa = $attr->{isa};
    if ($isa) {
        $isa =~ s/^['"]//;
        $isa =~ s/['"]$//;
    }
    if ($isa) {
        if (Mouse::TypeRegistry->optimized_constraints()->{$isa}) {
            $accessor .= "my \$constraint = Mouse::TypeRegistry->optimized_constraints()->{'$isa'};\n";
        } else {
            $accessor .= "my \$constraint = sub { Mouse::Util::blessed(\$_) && Mouse::Util::blessed(\$_) eq '$isa' };\n";
        }
    }
    if (my $default = $attr->{default}) {
        $accessor .= "my \$default = $attr->{default};\n";
    }
    $accessor .= "sub $name {\n";
    if ($attr->{is} =~ /rw/) {
        $accessor .= 'if (scalar(@_) >= 2) {' . "\n";

        my $value = '$_[1]';

        if ($isa) {
            if ($attr->{coerce}) {
                $accessor .= $value." = Mouse::TypeRegistry->typecast_constraints('$klass', '$isa', $value);";
            }
            $accessor .= 'local $_ = '.$value.';';
            my $constraint = sub { };
            $accessor .= "
                unless (\$constraint->()) {
                    my \$display = defined(\$_) ? overload::StrVal(\$_) : \"undef\";
                    Carp::confess(\"Attribute ($name) does not pass the type constraint because: Validation failed for \\'$isa\\' failed with value \$display\");
            }" . "\n"
        }

        # if there's nothing left to do for the attribute we can return during
        # this setter
        $accessor .= 'return ' if !$attr->{weak_ref} && !$attr->{trigger} && !$attr->{auto_deref};

        $accessor .= $self.'->{'.$key.'} = '.$value.';' . "\n";

        if ($attr->{weak_ref}) {
            $accessor .= 'Mouse::Util::weaken('.$self.'->{'.$key.'}) if ref('.$self.'->{'.$key.'});' . "\n";
        }

        die "This module doesn't support trigger" if $attr->{trigger};

        $accessor .= "}\n";
    }
    else {
        $accessor .= 'Carp::confess "Cannot assign a value to a read-only accessor" if scalar(@_) >= 2;' . "\n";
    }

    if ($attr->{lazy}) {
        $accessor .= $self.'->{'.$key.'} = ';

        $accessor .= $attr->{builder}
                ? $self.'->$builder'
                    : ref($attr->{default}) eq 'CODE'
                    ? '$default->('.$self.')'
                    : '$default';
        $accessor .= ' if !exists '.$self.'->{'.$key.'};' . "\n";
    }

    if ($attr->{auto_deref}) {
        die "THIS MODULE DOESN'T SUPPORT DEREF";
    }

    $accessor .= 'return '.$self.'->{'.$key.'};
        }
    }';
    $accessor;
}

sub generate_constructor_method_inline {
    my ($klass, $attrs) = @_;
    my @attrs = @$attrs;

    my $buildargs = _generate_BUILDARGS();
    my $processattrs = _generate_processattrs($klass, \@attrs);

    <<"...";
    sub new {
        my \$class = shift;
        my \$args = $buildargs;
        my \$instance = bless {}, \$class;
        $processattrs;
        return \$instance;
    }
...
}

sub _generate_processattrs {
    my ($class, $attrs) = @_;
    my @res;
    for my $attr (@$attrs) {
        my $set_value = do {
            my @code;

            if ($attr->{coerce}) {
                push @code, "my \$value = Mouse::TypeRegistry->typecast_constraints('$class', $attr->{isa}, \$args->{'$attr->{name}'});";
            }
            else {
                push @code, "my \$value = \$args->{'$attr->{name}'};";
            }

            # this one is very slow. skip this in cgi mode.
#           if ($attr->{isa}) {
#               push @code, "\$attrs[$index]->verify_type_constraint( \$value );";
#           }

            push @code, "\$instance->{'$attr->{name}'} = \$value;";

            if ($attr->{weak_ref}) {
                push @code, "Mouse::Util::weaken( \$instance->{'$attr->{name}'} ) if ref( \$value );";
            }

            if ( $attr->{trigger} ) {
                die "this module doesn't support trigger";
            }

            join "\n", @code;
        };

        my $make_default_value = do {
            my @code;

            if ( $attr->{default} || $attr->{builder} ) {
                unless ( $attr->{lazy} ) {
                    push @code, "my \$value = ";

                    if ($attr->{coerce}) {
                        push @code, "Mouse::TypeRegistry->typecast_constraints('$class', $attr->{isa}, ";
                    }

                        if ($attr->{builder}) {
                            push @code, "\$instance->$attr->{builder}";
                        }
                        elsif (ref($attr->{default}) =~ /^sub /) {
                            push @code, "@{[ $attr->{default} ]}->()";
                        }
                        else {
                            push @code, "$attr->{default}";
                        }

                    if ($attr->{coerce}) {
                        push @code, ");";
                    }
                    else {
                        push @code, ";";
                    }

                    if ($attr->{isa}) {
                        # "this module doesn't use type constraints";
                    }

                    push @code, "\$instance->{'$attr->{name}'} = \$value;";

                    if ($attr->{weak_ref}) {
                        push @code, "weaken( \$instance->{'$attr->{name}'} ) if ref( \$value );";
                    }
                }
                join "\n", @code;
            }
            else {
                if ( $attr->{required} ) {
                    qq{Carp::confess("Attribute ($attr->{name}) is required");};
                } else {
                    ""
                }
            }
        };
        my $code = <<"...";
            {
                if (exists(\$args->{'$attr->{name}'})) {
                    $set_value;
                } else {
                    $make_default_value;
                }
            }
...
        push @res, $code;
    }
    return join "\n", @res;
}

sub _generate_BUILDARGS {
    <<'...';
    do {
        if ( scalar @_ == 1 ) {
            if ( defined $_[0] ) {
                ( ref( $_[0] ) eq 'HASH' )
                || Carp::confess "Single parameters to new() must be a HASH ref";
                +{ %{ $_[0] } };
            }
            else {
                +{};
            }
        }
        else {
            +{@_};
        }
    };
...
}

sub replace_node {
    my ($parent, $child, $src) = @_;
    my $token = PPI::Token::Word->new($src);
    $parent->__replace_child($child, $token);
}

sub main {
    say "package HTTP::Engine::CGI;";

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
        # call ->import();
        $doc->find(
            sub {
                if ($_[1]->isa('PPI::Statement::Include')) {
                    if ($_[1]->module =~ /^HTTP::Engine/) {
                        eval {
                            my $content = $_[1]->content;
                            if ($content =~ /^use\s*(HTTP::Engine\S+)\s*(.*?);$/ms) {
                                my ($pkg, $args) = ($1, $2);
                                if ($pkg->can('import') && $pkg !~ /HTTP::Engine::(Util|Response|Request)/) {
                                    replace_node($_[0], $_[1], "BEGIN { ${pkg}::import('${pkg}', $args); }\n");
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
        (my $klass = $file) =~ s!/!::!g;
        $klass =~ s!\.pm$!!;
        my @attrs;
        $doc->find(
            sub {
                eval {
                    if ($_[1]->isa('PPI::Statement') && $_[1] =~ /^has/ && $_[1] !~ /\$attr/) {
                        warn "WHY?" unless $_[1]->schild(0) eq 'has';
                        my $name = $_[1]->schild(1)->content;
                        my ($args, ) = @{ $_[1]->find('PPI::Statement::Expression') || [] } or die "missing expression";
                        my @args = $args->children;
                        my $expect_key = 1;
                        my @args_result;
                        while (my $elem = shift @args) {
                            next if $elem->isa('PPI::Token::Whitespace');
                            next if $elem->isa('PPI::Token::Operator');

                            if ($expect_key) {
                                push @args_result, "$elem";
                                $expect_key = 0;
                            } else {
                                if ($elem->isa('PPI::Token::Word') && $elem eq 'sub') {
                                    my $content;
                                    while (my $block = shift @args) {
                                        next if $block->isa('PPI::Token::Whitespace');
                                        unless ($block->isa('PPI::Structure::Block')) {
                                            warn "invalid token: @{[ ref $block ]} $elem, $block ,$_[1]";
                                            warn join '    ---- ', @args;
                                            exit;
                                        }
                                        $content = "sub $block";
                                        last;
                                    }
                                    push @args_result, $content;
                                } else {
                                    push @args_result, "$elem";
                                }
                                $expect_key = 1;
                            }
                        }

                        $name =~ s/^['"]//;
                        $name =~ s/['"]$//;
                        my $attr = {@args_result, name => $name};
                        my $src = process_accessor($name, $klass, $attr) . "\n";
                        if (my $handles = $attr->{handles}) {
                            my $handles = eval $handles;
                            die $@ if $@;
                            for my $handle (@$handles) {
                                $handle =~ s/^['"]//;
                                $handle =~ s/['"]$//;
                                $src .= "sub $handle { shift->$name->$handle(\@_) }\n";
                            }
                        }
                        eval $src;
                        if ($@) {
                            warn "------------- START";
                            warn $@;
                            warn $src;
                            warn "------------- END";
                        } else {
                            replace_node($_[0], $_[1], $src);
                        }
                        push @attrs, $attr;
                    }
                };
                warn $@ if $@;
            },
        );
        my $content = $doc->serialize;
        $content =~ s/^__END__$//smg;
        $content =~ s/__PACKAGE__->meta->make_immutable(\(\))?;/
            ';' . generate_constructor_method_inline($klass, \@attrs) . ';sub DESTRUCTOR { }'
        /e;
        say "{\n$content\n}\n";
    }

    say "1;";
}

__END__
