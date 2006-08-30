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
    $prefix = '' if ! defined $prefix;

    if (UNIVERSAL::isa($in, 'ARRAY')) {
        die "Not handling blessed ARRAY" if ref $in ne 'ARRAY';
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
        die "Not handling blessed HASH" if ref $in ne 'HASH';
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
        die "Not sure how to handle that type ($in)";
    }

    return $out;
}

sub _flatten_escape {
    my $val = shift;
    return undef if ! defined $val;
    return '""'  if ! length $val;
    return $val  if $val !~ /[.:\"]/;
    $val =~ s/\"/\\\"/g;
    return '"'.$val.'"';
}

###----------------------------------------------------------------###

sub complex_to_query {
    my $flat = complex_to_flat(@_);
    return join "&", map {
        my $key = $_;
        my $val = $flat->{$_};
        foreach ($key, $val) {
            s/([^\w.\-\ \:])/sprintf('%%%02X', ord $1)/eg;
            y/ /+/;
        }
        "$_=$val";
    } sort keys %$flat;
}

###----------------------------------------------------------------###

1;
