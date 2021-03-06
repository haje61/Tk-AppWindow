
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Plugins::Keyboard') };

my $settingsfolder = 't/settings';


CreateTestApp(
	-plugins => [qw[Keyboard]],
	-commands => [
		'on_press_o' => [sub { print "o-key pressed\n" }],
	],
	-keyboardbindings => [
		on_press_o => 'o'
	],
);

my $plug = $app->GetPlugin('Keyboard');

@tests = (
	[sub { return $plug->Name eq 'Keyboard' }, 1, 'plugin Keyboard loaded']
);

$app->MainLoop;

