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
    $qr_chunk          = '([^.:]*)';
    $qr_chunk_quoted   = '"((?:[^"]*|\\\\")+)(?<!\\\\)(")';
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
            $_ = '' if ! defined;
            s/([^\w.\-\ \:])/sprintf('%%%02X', ord $1)/eg;
            y/ /+/;
        }
        "$_=$val";
    } sort keys %$flat;
}

sub query_to_complex {
    my $str = shift;
    return {} if ! defined $str || ! length $str;

    require CGI;
    my $q = CGI->new(\$str);

    my %hash = ();
    foreach my $key ($q->param) {
        my @val = $q->param($key);
        $hash{$key} = ($#val <= 0) ? $val[0] : \@val;
    }

    return flat_to_complex(\%hash);
}

###----------------------------------------------------------------###

1;
