
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Keyboard') };


createapp(
	-extensions => [qw[Keyboard]],
	-commands => [
		'on_press_o' => [sub { print "o-key pressed\n" }],
	],
	-keyboardbindings => [
		on_press_o => 'o'
	],
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('Keyboard');
}

@tests = (
	[sub { return $ext->Name }, 'Keyboard', 'extension Keyboard loaded']
);

starttesting;

