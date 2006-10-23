package Data::URIEncode;

=head1 NAME

Data::URIEncode - Allow complex data structures to be encoded using flat URIs.

=cut

use strict;
use base qw(Exporter);
use vars qw($VERSION
            @EXPORT_OK
            $MAX_ARRAY_EXPAND
            $DUMP_BLESSED_DATA
            $qr_chunk
            $qr_chunk_quoted
            );

BEGIN {
    $VERSION           = '0.10';
    @EXPORT_OK         = qw(flat_to_complex complex_to_flat query_to_complex complex_to_query);
    $MAX_ARRAY_EXPAND  = 100;
    $DUMP_BLESSED_DATA = 1 if ! defined $DUMP_BLESSED_DATA;
    $qr_chunk          = "([^.:]*)";
    $qr_chunk_quoted   = "'((?:[^']*|\\\\')+)(?<!\\\\)(')";
}

###----------------------------------------------------------------###

sub flat_to_complex {
    my $in = shift || die "Missing hashref";

    my $out = {};

    foreach my $key (sort keys %$in) {
        my $copy = ($key =~ /^[.:]/) ? $key : ".$key";
        my $ref  = $out;
        my $name = 'root';

        while ($copy =~ s/^ ([.:]) $qr_chunk_quoted//xo
               || $copy =~ s/^ ([.:]) $qr_chunk//xo) {
            my ($sep, $next) = ($1, $2);
            $next =~ s/\\\'/\'/g if $3;

            if (ref $ref eq 'ARRAY') {
                if (! exists $ref->[$name]) {
                    $ref->[$name] = $sep eq ':' ? [] : {};
                } else {
                    die "Can't coerce array into hash near \"$name\" while unfolding $key"
                        if $sep ne ':';
                }
                die "Can't use $name as index value for an array while unfolding $key"
                    if $name !~ /^\d+$/;
                die "Can't expand array in $key by more than $MAX_ARRAY_EXPAND"
                    if $name - $#$ref > $MAX_ARRAY_EXPAND;
                $ref  = $ref->[$name];
                $name = $next;
            } elsif (ref $ref eq 'HASH') {
                if (! exists $ref->{$name}) {
                    $ref->{$name} = $sep eq ':' ? [] : {};
                }
                $ref  = $ref->{$name};
                $name = $next;
            } else {
                die "Unknown type during unfold of $key";
            }

            if ($sep eq ':') {
                die "Can't coerce hash into array near \"$name\" while unfolding $key"
                    if ref $ref eq 'HASH';
            } else {
                die "Can't coerce array into hash near \"$name\" while unfolding $key"
                    if ref $ref eq 'ARRAY';
            }
        }


        if (ref $ref eq 'HASH') {
            $ref->{$name} = $in->{$key};
        } elsif (ref $ref eq 'ARRAY') {
            die "Can't use $name as index value for an array while unfolding $key"
                if $name !~ /^\d+$/;
            die "Can't expand array in $key by more than $MAX_ARRAY_EXPAND"
                if $name - $#$ref > $MAX_ARRAY_EXPAND;
            $ref->[$name] = $in->{$key};
        } else {
            die "Can't unfold $key at level $name (scalar value exists)";
        }
    }

    return $out->{'root'};
}

###----------------------------------------------------------------###

sub complex_to_flat {
    my $in     = shift;
    my $out    = shift || {};
    my $prefix = shift;
    $prefix = '' if ! defined $prefix;

    if (UNIVERSAL::isa($in, 'ARRAY')) {
        die "Not handling blessed ARRAY" if ref $in ne 'ARRAY' && ! $DUMP_BLESSED_DATA;
        foreach my $i (0 .. $#$in) {
            if (ref $in->[$i]) {
                complex_to_flat($in->[$i], $out, "$prefix:"._flatten_escape($i));
            } elsif (defined $in->[$i] || $i == $#$in) {
                my $key = "$prefix:"._flatten_escape($i);
                $key =~ s/^\.//; # leading . is not necessary (it is the default)
                $out->{$key} = $in->[$i];
            }
        }
    } elsif (UNIVERSAL::isa($in, 'HASH')) {
        die "Not handling blessed HASH" if ref $in ne 'HASH' && ! $DUMP_BLESSED_DATA;
        while (my($key, $val) = each %$in) {
            if (ref $val) {
                complex_to_flat($val, $out, "$prefix."._flatten_escape($key));
            } else {
                $key = "$prefix."._flatten_escape($key);
                $key =~ s/^\.//; # leading . is not necessary (it is the default)
                $out->{$key} = $val;
            }
        }
    } else {
        die "Need a hash or array" if ! defined $in;
        die "Not sure how to handle that type ($in)";
    }

    return $out;
}

sub _flatten_escape {
    my $val = shift;
    return undef if ! defined $val;
    return "''"  if ! length $val;
    return $val  if $val !~ /[.:\']/;
    $val =~ s/\'/\\\'/g;
    return "'".$val."'";
}

###----------------------------------------------------------------###

sub complex_to_query {
    my $flat = complex_to_flat(@_);
    return join "&", map {
        my $key = $_;
        my $val = $flat->{$_};
        foreach ($key, $val) {
            $_ = '' if ! defined;
            s/([^\w.\-\ \:])/sprintf('%%%02X', ord $1)/eg;
            y/ /+/;
        }
        "$key=$val";
    } sort keys %$flat;
}

sub query_to_complex {
    my $q;
    my $str = shift;

    if (! ref $str) { # normal string
        return {} if ! defined $str || ! length $str;
        require CGI;
        $q = CGI->new(\$str);

    } elsif (ref $str eq 'SCALAR') { # ref to a string
        return {} if ! defined $$str || ! length $$str;
        require CGI;
        $q = CGI->new($str);

    } elsif (ref $str eq 'HASH') { # passed a data hash instead
        return flat_to_complex($str);

    } elsif (UNIVERSAL::can($str, 'param')) { # CGI looking object
        $q = $str;

    } else {
        die "Not sure how to handle \"$str\" - should pass a string, ref to a string, a hashref, or a CGI compatible object";
    }

    my %hash = ();
    foreach my $key ($q->param) {
        my @val = $q->param($key);
        $hash{$key} = ($#val <= 0) ? $val[0] : \@val;
    }

    return flat_to_complex(\%hash);
}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

    use Data::URIEncode qw(flat_to_complex complex_to_flat);

    my $data = {
        foo => {
            bar => 'bing',
        },
        baz => [123],
    };

    my $flat = complex_to_flat($data);

    # $data looks like:
    $data = {
       'foo.bar' => 'bing',
       'baz:0'   => 123,
    };

    # put data back to how it was
    $data = flat_to_complex($flat);


    ### some html form somewhere
    <form>
    <input type="text" name="foo.bar.baz" value="brum">
    <input type="text" name="bing:2" value="blang">
    <input type="text" name="'key with :, ., and \''.red" value="blue">
    </form>

    ### when the form is submitted to the following code
    use CGI;
    use Data::URIEncode qw(query_to_complex);

    my $q = CGI->new;
    my $data = query_to_complex($q);

    ### data will look like
    $data = {
        foo => {
            bar => {
               baz = "brum",
            },
        },
        bing => [
            undef,
            undef,
            "blang",
        ],
        "key with :, ., and '" => {
            red = "blue",
        },
    };

=head1 DESCRIPTION

The world of the web works off of URI's. The Query string portion
of URIs already support encoding of key/value paired data - they
just don't natively allow for for complex data structures.

There are modules or encodings that do support arbitrarily complex
data structures.  JSON, YAML and Data::Dumper all have their own
way of encoding complex structures.  But then to pass them across
the web, you usually still have to URL encode them and pass them
via a form parameter.

Data::URIEncode allows for encoding and decoding complex (multi
level datastructures) using native Query String manipulators (such
as CGI.pm).  It takes complex data and turns it into a flat hashref
which can then be turned into a URI query string using URL encoding.
It also takes a flat hashref of data passed in and translates it
back to a complex structure.

One benefit of using Data::URIEncode is that a standard submission
from a standard html form can automatically be translated into complex
data even though it arrived in a "flat" form.  This somewhat mimics the
abilities of XForms without introducing the complexity of XForms.

=head1 RULES

=head1 FUNCTIONS

=over 4

=item flat_to_complex

Takes a hashref of simple key value pairs.  Returns a data structure based
on the the parsed key value pairs.  The parsing proceeds according to the
rules listed in RULES.

=item complex_to_flat

Takes a complex data structure and turns it into a flat hashref (single level
key/value pairs only).  The parsing proceeds according to the rules listed in
RULES.

=item complex_to_query

Similar to complex_to_flat, except that the flattened hashref is then translated
into query string suitable for use in a URI.

=item query_to_complex

Takes one of a string, a reference to a string, a hash, or a CGI.pm compatible object
and translates it into a complex data structure.  Similar to flat_to_complex, exempt
that a first step is taken to access the query parameters from the CGI compatible object
or string.  If a string or string ref is given, the CGI module is used to parse the string
into an initial flat hash of key value pairs (using the param method).  If another module
is desired over, CGI.pm you must initialize it with the data to be parsed prior to passing
the object to the query_to_complex function.

    my $data = query_to_complex("foo.bar:0=baz");

    my $data = query_to_complex(\ "foo.bar:0=baz");

    my $data = query_to_complex({"foo.bar:0" => "baz"}); # same as flat_to_complex

    my $cgi  = CGI->new(\ "foo.bar:0=baz");
    my $data = query_to_complex($cgi);

    my $cgi  = CGI->new; # use the values passed in from STDIN
    my $data = query_to_complex($cgi);

=back

=head1 VARIABLES

=over 4

=item C<$MAX_ARRAY_EXPAND>

Default value is 100.  This variable is used to determine how large
flat_to_complex will allow an array to be expanded beyond its current size.
An array can grow as large as you have memory, but intermediate values must
exist.

Without this value, somebody could specify foo:1000000000000=bar and your server
would attempt to set the 1000000000000th index of the foo value to bar.

The string "foo:101=bar" would die, but the string "foo:50=bar&foo:101=baz" would not
die because the intermediate foo->[50] increments the foo arrayref by 51 and the subsequent
foo->[101] call increments the foo arrayref by only 51.

=item C<$DUMP_BLESSED_DATA>

Default is true.  If true, blessed hashrefs and arrayrefs will also be added to the
flat data returned by complex_to_flat.  If false, bless hashrefs and arrayrefs will be
skipped.

=back

=head1 BUGS

Circular refs are not detected.  Any attempt to dump a struture with
cirular refs will result in an infinite loop.  There is no immediate plan to
add circular ref tracking.

=head1 AUTHOR

Paul Seamons perlspam at seamons dot com

=head1 LICENSE

This library may be distributed under the same terms as Perl itself.

=cut
