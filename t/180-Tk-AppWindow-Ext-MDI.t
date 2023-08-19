
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 500;

use Test::More tests => 5;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::MDI');
};

require TestTextManager;

createapp(
	-extensions => [qw[Art MenuBar MDI ToolBar]],
	-configfolder => 't/settings',
	-contentmanagerclass => 'TestTextManager',
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('MDI');
}

@tests = (
	[sub { return defined $ext }, 1, 'Extension defined'],
	[sub { return $ext->Name  }, 'MDI', 'Extension MDI loaded'],
);

# $app->cmdExecute('file_new');
starttesting;

