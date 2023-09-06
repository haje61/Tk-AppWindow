
use strict;
use warnings;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::ToolBar') };


createapp(
	-extensions => [qw[ToolPanel Art MenuBar ]],
);

my $ext;
if (defined $app) {
	$ext = $app->extGet('ToolPanel');
}

@tests = (
	[sub { return $ext->Name }, 'ToolPanel', 'extension ToolPanel loaded']
);

starttesting;
