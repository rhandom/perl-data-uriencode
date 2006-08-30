# -*- Mode: Perl; -*-

=head1 NAME

55_urlencode.t - Test the urlencode utility.

=cut

use strict;
use Test::More tests => 36;

use_ok('URLEncode');

my $data = {
    'foo.0' => 'bar',
};

my $out = eval { URLEncode::flat_to_complex($data) };
ok($out, "Ran flat_to_complex");
ok($out->{'foo'}->[0] eq 'bar', 'foo.0');


$data = {
    'foo.2' => 'bar',
    'foo.5' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->[2] eq 'bar', 'foo.2');
ok($out->{'foo'}->[5] eq 'bing', 'foo.5');
ok(! defined $out->{'foo'}->[4], 'foo.4');


$data = {
    'foo' => 'bar',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'} eq 'bar', 'foo.2');


$data = {
    'foo.bar.baz' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{'bar'}->{'baz'} eq 'bing', 'foo.bar.baz');


$data = {
    'foo:bar:baz' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{'bar'}->{'baz'} eq 'bing', 'foo:bar:baz');

$data = {
    'foo:0' => 'bar',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{'0'} eq 'bar', 'foo:0');


$data = {
    'foo.10000' => 'bing',
};
ok(! ($out = eval { URLEncode::flat_to_complex($data) }), "Couldn't run - too big ($@)");


$data = {
    'foo'     => 'bing',
    'foo.bar' => 'bing',
};
ok(! ($out = eval { URLEncode::flat_to_complex($data) }), "Couldn't run - overlap of keys ($@)");


$data = {
    'foo.1' => 'bing',
    'foo.a' => 'bing',
};
ok(! ($out = eval { URLEncode::flat_to_complex($data) }), "Couldn't run - using a for index ($@)");


$data = {
    '.foo' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{''}->{'foo'} eq 'bing', '.foo');


$data = {
    'foo.' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{''} eq 'bing', 'foo.');


$data = {
    'foo..bar' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{''}->{'bar'} eq 'bing', 'foo..bar');


$data = {
    ' . . ' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{' '}->{' '}->{' '} eq 'bing', ' . . ');


$data = {
    '".".foo' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'.'}->{'foo'} eq 'bing', '".".foo');


$data = {
    'foo."."' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex");
ok($out->{'foo'}->{'.'} eq 'bing', 'foo."."');


$data = {
    '"."."."."."' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex ($@)");
ok($out->{'.'}->{'.'}->{'.'} eq 'bing', '"."."."."."');


$data = {
    '"."' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex ($@)");
ok($out->{'.'} eq 'bing', '"."');

$data = {
    '"\"\""' => 'bing',
};
ok(($out = eval { URLEncode::flat_to_complex($data) }), "Ran flat_to_complex ($@)");
ok($out->{'""'} eq 'bing', '"\"\""');
