
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Plugins::Balloon') };

my $settingsfolder = 't/settings';


CreateTestApp(
	-plugins => [qw[Balloon]],
);

my $plug = $app->GetPlugin('Balloon');

@tests = (
	[sub { return $plug->Name eq 'Balloon' }, 1, 'plugin Balloon loaded']
);

$app->MainLoop;

