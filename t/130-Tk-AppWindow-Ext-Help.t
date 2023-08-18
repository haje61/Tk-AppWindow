
use strict;
use warnings;
sleep 1;

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Help') };


createapp(
	-extensions => [qw[Art MenuBar Help]],
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('Help');
}

@tests = (
	[sub { return $ext->Name }, 'Help', 'extension Help loaded']
);

starttesting;
