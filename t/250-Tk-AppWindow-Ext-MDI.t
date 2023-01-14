
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
$delay = 500;

use Test::More tests => 5;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::MDI');
};

require TestTextManager;

CreateTestApp(
	-extensions => [qw[Art MenuBar MDI ToolBar]],
	-configfolder => $settingsfolder,
	-contentmanagerclass => 'TestTextManager',
);

my $ext = $app->GetExt('MDI');

@tests = (
	[sub { return defined $ext }, 1, 'Extension defined'],
	[sub { return $ext->Name eq 'MDI' }, 1, 'Extension MDI loaded'],
);

# $app->CommandExecute('file_new');
$app->MainLoop;

