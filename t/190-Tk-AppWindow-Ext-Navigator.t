
use strict;
use warnings;
sleep 1;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
$delay = 1500;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Navigator');
};

require TestTextManager;

createapp(
	-appname => 'Navigator',
	-extensions => [qw[Art Balloon MenuBar ToolBar StatusBar MDI Navigator]],
	-configfolder => 't/settings',
	-contentmanagerclass => 'TestTextManager',
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('Navigator');
}

@tests = (
	[sub { return $ext->Name }, 'Navigator', 'extension Navigator loaded']
);

starttesting;
