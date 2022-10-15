
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::ConfigFolder') };


CreateTestApp(
	-configfolder => $settingsfolder,
	-extensions => [qw[ConfigFolder]],
);

my $plug = $app->GetExt('ConfigFolder');

@tests = (
	[sub { return $plug->Name eq 'ConfigFolder' }, 1, 'plugin ConfigFolder loaded']
);

$app->MainLoop;

