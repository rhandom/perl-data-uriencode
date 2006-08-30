# -*- Mode: Perl; -*-

=head1 NAME

55_urlencode.t - Test the urlencode utility.

=cut

use strict;
use Test::More tests => 55;

use_ok('URLEncode');

my $data;
my $out;

$data = {
    'foo:2' => 'bar',
    'foo:5' => 'bing',
};
ok(($out = URLEncode::flat_to_complex($data)), "Ran flat_to_complex");
ok($out->{'foo'}->[2] eq 'bar', 'foo.2');
ok($out->{'foo'}->[5] eq 'bing', 'foo.5');
ok(! defined $out->{'foo'}->[4], 'foo.4');

ok(URLEncode::flat_to_complex({'foo'         => 'a'})->{'foo'}             eq 'a', 'key: (foo)');
ok(URLEncode::flat_to_complex({'foo.bar.baz' => 'a'})->{'foo'}{'bar'}{baz} eq 'a', 'key: (foo.bar.baz)');
ok(URLEncode::flat_to_complex({'foo:0'       => 'a'})->{'foo'}->[0]        eq 'a', 'key: (foo:0)');
ok(URLEncode::flat_to_complex({'foo:0:2'     => 'a'})->{'foo'}->[0]->[2]   eq 'a', 'key: (foo:0:2)');
ok(URLEncode::flat_to_complex({'foo.0'       => 'a'})->{'foo'}->{'0'}      eq 'a', 'key: (foo.0)');
ok(URLEncode::flat_to_complex({'foo.0.2'     => 'a'})->{'foo'}->{'0'}{'2'} eq 'a', 'key: (foo.0.2)');
ok(URLEncode::flat_to_complex({'foo.'        => 'a'})->{'foo'}->{''}       eq 'a', 'key: (foo.)');
ok(URLEncode::flat_to_complex({'.foo'        => 'a'})->{'foo'}             eq 'a', 'key: (.foo)');
ok(URLEncode::flat_to_complex({'"".foo'      => 'a'})->{''}->{'foo'}       eq 'a', 'key: ("".foo)');
ok(URLEncode::flat_to_complex({'foo..bar'    => 'a'})->{'foo'}{''}{'bar'}  eq 'a', 'key: (foo..bar)');
ok(URLEncode::flat_to_complex({' '           => 'a'})->{' '}               eq 'a', 'key: ( )');
ok(URLEncode::flat_to_complex({' . '         => 'a'})->{' '}->{' '}        eq 'a', 'key: ( . )');
ok(URLEncode::flat_to_complex({' . . '       => 'a'})->{' '}->{' '}->{' '} eq 'a', 'key: ( . . )');
ok(URLEncode::flat_to_complex({'foo."."'     => 'a'})->{'foo'}->{'.'}      eq 'a', 'key: (foo.".")');
ok(URLEncode::flat_to_complex({'".".foo'     => 'a'})->{'.'}->{'foo'}      eq 'a', 'key: (".".foo)');
ok(URLEncode::flat_to_complex({'"."'         => 'a'})->{'.'}               eq 'a', 'key: (".")');
ok(URLEncode::flat_to_complex({'"."."."'     => 'a'})->{'.'}->{'.'}        eq 'a', 'key: (".".".")');
ok(URLEncode::flat_to_complex({'"."."."."."' => 'a'})->{'.'}->{'.'}->{'.'} eq 'a', 'key: (".".".".".")');
ok(URLEncode::flat_to_complex({'"\"\""'      => 'a'})->{'""'}              eq 'a', 'key: ("\"\"")');
ok(URLEncode::flat_to_complex({'""'          => 'a'})->{''}                eq 'a', 'key: ("")');
ok(URLEncode::flat_to_complex({''            => 'a'})->{''}                eq 'a', 'key: ()');
ok(URLEncode::flat_to_complex({':3'          => 'a'})->[3]                 eq 'a', 'key: (:3)');

ok(URLEncode::flat_to_complex({'.foo'         => 'a'})->{'foo'}             eq 'a', 'key: (.foo)');
ok(URLEncode::flat_to_complex({'.foo.bar.baz' => 'a'})->{'foo'}{'bar'}{baz} eq 'a', 'key: (.foo.bar.baz)');
ok(URLEncode::flat_to_complex({'.foo:0'       => 'a'})->{'foo'}->[0]        eq 'a', 'key: (.foo:0)');
ok(URLEncode::flat_to_complex({'.foo:0:2'     => 'a'})->{'foo'}->[0]->[2]   eq 'a', 'key: (.foo:0:2)');
ok(URLEncode::flat_to_complex({'.foo.0'       => 'a'})->{'foo'}->{'0'}      eq 'a', 'key: (.foo.0)');
ok(URLEncode::flat_to_complex({'.foo.0.2'     => 'a'})->{'foo'}->{'0'}{'2'} eq 'a', 'key: (.foo.0.2)');
ok(URLEncode::flat_to_complex({'.foo.'        => 'a'})->{'foo'}->{''}       eq 'a', 'key: (.foo.)');
ok(URLEncode::flat_to_complex({'."".foo'      => 'a'})->{''}->{'foo'}       eq 'a', 'key: (."".foo)');
ok(URLEncode::flat_to_complex({'.foo..bar'    => 'a'})->{'foo'}{''}{'bar'}  eq 'a', 'key: (.foo..bar)');
ok(URLEncode::flat_to_complex({'. '           => 'a'})->{' '}               eq 'a', 'key: (. )');
ok(URLEncode::flat_to_complex({'. . '         => 'a'})->{' '}->{' '}        eq 'a', 'key: (. . )');
ok(URLEncode::flat_to_complex({'. . . '       => 'a'})->{' '}->{' '}->{' '} eq 'a', 'key: (. . . )');
ok(URLEncode::flat_to_complex({'.foo."."'     => 'a'})->{'foo'}->{'.'}      eq 'a', 'key: (.foo.".")');
ok(URLEncode::flat_to_complex({'.".".foo'     => 'a'})->{'.'}->{'foo'}      eq 'a', 'key: (.".".foo)');
ok(URLEncode::flat_to_complex({'."."'         => 'a'})->{'.'}               eq 'a', 'key: (.".")');
ok(URLEncode::flat_to_complex({'."."."."'     => 'a'})->{'.'}->{'.'}        eq 'a', 'key: (.".".".")');
ok(URLEncode::flat_to_complex({'."."."."."."' => 'a'})->{'.'}->{'.'}->{'.'} eq 'a', 'key: (.".".".".".")');
ok(URLEncode::flat_to_complex({'."\"\""'      => 'a'})->{'""'}              eq 'a', 'key: (."\"\"")');
ok(URLEncode::flat_to_complex({'.""'          => 'a'})->{''}                eq 'a', 'key: (."")');
ok(URLEncode::flat_to_complex({'.'            => 'a'})->{''}                eq 'a', 'key: (.)');

ok(! eval { URLEncode::flat_to_complex({'.1' => 'a', ':1' => 'a'      }) }, "Can't coerce ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo.1' => 'a', 'foo:1' => 'a'}) }, "Can't coerce ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo.1' => 'a', '"foo":1'=>'a'}) }, "Can't coerce ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo:10000'                   }) }, "Couldn't run - too big ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo'   => 'a', 'foo.a' => 'a'}) }, "Couldn't run - overlap of keys ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo:1' => 'a', 'foo:a' => 'a'}) }, "Couldn't run - using a for index ($@)");
ok(! eval { URLEncode::flat_to_complex({'foo:a' => 'a'                }) }, "Couldn't run - using a for index ($@)");
ok(! eval { URLEncode::flat_to_complex({':a' => 'a'                   }) }, "Couldn't run - using a for index ($@)");

