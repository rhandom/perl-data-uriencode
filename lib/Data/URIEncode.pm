package URLEncode;

=head1 NAME

URLEncode - utilities for handling data passed via URL

=cut

use strict;
use vars qw($MAX_ARRAY_EXPAND
            $qr_chunk
            $qr_chunk_quoted
            );

BEGIN {
    $MAX_ARRAY_EXPAND = 100;
    $qr_chunk = '[^.:]*';
    $qr_chunk_quoted = '"((?:[^"]*|\\\\")+)(?<!\\\\)(")';
}

###----------------------------------------------------------------###

sub flat_to_complex {
    my $in = shift || die "Missing hashref";

    my $out = {};
    foreach my $key (sort keys %$in) {
        my $val = $in->{$key};

        ### non-complex quoted keys
        if ($key =~ /^ $qr_chunk_quoted $/xo) {
            $key = $1;
            $key =~ s/\\\"/\"/g;
            $out->{$key} = $val;
            next;

        ### normal keys
        } elsif ($key !~ /[.:]/) {
            $out->{$key} = $val;
            next;
        }

        # looks like foo.0.bar which would map to foo => [{bar => $val}]
        my $copy = $key;
        my $ref  = $out;
        $copy =~ s/^ $qr_chunk_quoted //sxo || $copy =~ s/^ ($qr_chunk) //xo;
        my $name = $1;
        $name =~ s/\\\"/\"/g if $2;

        while (   $copy =~ s/^ ([.:]) $qr_chunk_quoted//xo
               || $copy =~ s/^ ([.:]) ($qr_chunk)//xo) {
            my ($sep, $next) = ($1, $2);
            $name =~ s/\\\"/\"/g if $3;
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
                die "Can't use $name as index value for an array while unfolding $key"
                    if $name !~ /^\d+$/;
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
                $name = $next;
            } else {
                die "Can't unfold $key at level $name (scalar value exists)";
            }
        }
        if (ref $ref eq 'HASH') {
            $ref->{$name} = $val;
        } elsif (ref $ref eq 'ARRAY') {
            die "Can't use $name as index value for an array while unfolding $key"
                if $name !~ /^\d+$/;
            die "Can't expand array in $key by more than $MAX_ARRAY_EXPAND"
                if $name - $#$ref > $MAX_ARRAY_EXPAND;
            $ref->[$name] = $val;
        } else {
            die "Can't unfold $key at level $name (scalar value exists)";
        }
    }
    return $out;
}

###----------------------------------------------------------------###

1;
