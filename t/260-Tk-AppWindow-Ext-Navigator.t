
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Navigator');
};

$delay = 1500;
require TestTextManager;

CreateTestApp(
	-extensions => [qw[Art Balloon MenuBar ToolBar StatusBar MDI Navigator]],
	-configfolder => $settingsfolder,
	-contentmanagerclass => 'TestTextManager',
);

my $ext = $app->GetExt('Navigator');

@tests = (
	[sub { return $ext->Name eq 'Navigator' }, 1, 'plugin Navigator loaded']
);

$app->MainLoop;

