
use strict;
use warnings;
sleep 1;

use Test::Tk;
$mwclass = 'Tk::AppWindow';
use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::ConfigFolder') };


createapp(
	-configfolder => 't/settings',
	-extensions => [qw[ConfigFolder]],
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('ConfigFolder');
}

@tests = (
	[sub { return $ext->Name }, 'ConfigFolder', 'extension ConfigFolder loaded']
);

starttesting;

