
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Plugins::Help') };


CreateTestApp(
	-plugins => [qw[Art MenuBar Help]],
);

my $plug = $app->GetPlugin('Help');

@tests = (
	[sub { return $plug->Name eq 'Help' }, 1, 'plugin Help loaded']
);

$app->MainLoop;

