package URLEncode;

=head1 NAME

URLEncode - utilities for handling data passed via URL

=cut

use strict;
use vars qw($MAX_ARRAY_EXPAND);

BEGIN {
    $MAX_ARRAY_EXPAND = 100;
}

###----------------------------------------------------------------###

sub flat_to_complex {
    my $in = shift || die "Missing hashref";

    my $out = {};
    while (my($key, $val) = each %$in) {

        ### normal keys
        if ($key !~ /^[^.:]* (?: [.:] [^.:]*)+ $/x) {
            $out->{$key} = $val;
            next;
        }

        # looks like foo.0.bar which would map to foo => [{bar => $val}]
        my $copy = $key;
        $copy =~ s/^([^.:]*) //x;
        my $name = $1;
        my $ref  = $out;
        while ($copy =~ s/^ ([.:]) ([^.:]*)//x) {
            my ($sep, $next) = ($1, $2);
            if (ref $ref eq 'HASH') {
                if (! exists $ref->{$name}) {
                    if ($next =~ /^\d+$/ && $sep ne ':') {
                        $ref->{$name} = [];
                    } else {
                        $ref->{$name} = {};
                    }
                }
                $ref = $ref->{$name};
                $name = $next;
            } elsif (ref $ref eq 'ARRAY') {
                die "Can't use $name as index value for an array while expanding $key"
                    if $name =~ /\D/;
                die "Can't expand array in $key by more than $MAX_ARRAY_EXPAND"
                    if $name - $#$ref > $MAX_ARRAY_EXPAND;
                if (! exists $ref->[$name]) {
                    if ($next =~ /^\d+$/ && $sep ne ':') {
                        $ref->[$name] = [];
                    } else {
                        $ref->[$name] = {};
                    }
                }
                $ref = $ref->[$name];
                $name = $next || 0;
            } else {
                die "Can't unfold $key on top of $name";
            }
        }
        if (ref $ref eq 'HASH') {
            $ref->{$name} = $val;
        } elsif (ref $ref eq 'ARRAY') {
            die "Can't use $name as index value for an array while expanding $key"
                if $name =~ /\D/;
            die "Can't expand array in $key by more than $MAX_ARRAY_EXPAND"
                if $name - $#$ref > $MAX_ARRAY_EXPAND;
            $ref->[$name] = $val;
        } else {
            die "Not sure how we got here during unfold on $key";
        }
    }
    return $out;
}

###----------------------------------------------------------------###

1;
