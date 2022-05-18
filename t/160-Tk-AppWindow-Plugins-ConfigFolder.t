
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Plugins::ConfigFolder') };


CreateTestApp(
	-configfolder => $settingsfolder,
	-plugins => [qw[ConfigFolder]],
);

my $plug = $app->GetPlugin('ConfigFolder');

@tests = (
	[sub { return $plug->Name eq 'ConfigFolder' }, 1, 'plugin ConfigFolder loaded']
);

$app->MainLoop;

