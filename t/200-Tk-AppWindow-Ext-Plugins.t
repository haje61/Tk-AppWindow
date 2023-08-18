
use strict;
use warnings;
sleep 1;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
# $delay = 1500;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Plugins');
};

require TestTextManager;

createapp(
	-appname => 'Plugins',
	-extensions => [qw[Plugins]],
	-plugins => ['Test'],
);

my $ext;
# my $plug;
if (defined $app) {
	$ext = $app->GetExt('Plugins');
# 	$plug = $ext->GetPlugin('Test');
}

@tests = (
	[sub { return $ext->Name }, 'Plugins', 'extension Plugins loaded'],
# 	[sub { return $ext->GetPlugin('Test')->Name }, 'Test', 'plugin Test loaded',],
);

starttesting;
