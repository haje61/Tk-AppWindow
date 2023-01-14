
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::SDI') };

$delay = 1500;
require TestTextManager;
my $settingsfolder = 't/settings';


CreateTestApp(
	-configfolder => $settingsfolder,
	-extensions => [qw[Art ToolBar SDI]],
	-contentmanagerclass => 'TestTextManager',
);

my $plug = $app->GetExt('SDI');

@tests = (
	[sub { return $plug->Name eq 'SDI' }, 1, 'plugin SDI loaded']
);

$app->CommandExecute('file_new');
$app->MainLoop;

