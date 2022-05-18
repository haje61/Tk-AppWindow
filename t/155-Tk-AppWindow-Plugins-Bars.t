use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Plugins::Bars') };


CreateTestApp(
	-plugins => [qw[Bars]],
);

my $plug = $app->GetPlugin('Bars');

@tests = (
	[sub { return $plug->Name eq 'Bars' }, 1, 'plugin Help loaded']
);

$app->MainLoop;
