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
    $qr_chunk = '([^.:]*)';
    $qr_chunk_quoted = '"((?:[^"]*|\\\\")+)(?<!\\\\)(")';
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
            $next =~ s/\\\"/\"/g if $3;

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
    my $is_top;
    if (! defined $prefix || $prefix eq '') {
        $prefix = '';
        $is_top = 1;
    }


    return $out;
}

###----------------------------------------------------------------###

1;
