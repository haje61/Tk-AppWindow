
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Tk;

use Test::More tests => 4;
BEGIN { use_ok('Tk::DocumentTree') };
use File::Spec;

my @files = (
	'bin/simple_editor',
	't/057-Tk-DocumentTree.t',
	'Makefile.PL',
	'Changes',
	'lib/Tk/AppWindow.pm',
	'/home/haje/Anonymous-yin-yang-2.svg',
);

CreateTestApp(
);

my $dt = $app->DocumentTree(
)->pack(-expand => 1, -fill => 'both');

for (@files) {
	my $name = File::Spec->rel2abs($_);
	$dt->EntryAdd($name);
}

# $dt->EntryDelete('/home/haje/Anonymous-yin-yang-2.svg');

@tests = (
	[sub {  return defined $dt }, '1', 'Can create']
);

$app->MainLoop;


