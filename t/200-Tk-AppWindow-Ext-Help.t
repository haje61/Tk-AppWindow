
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Help') };


CreateTestApp(
	-extensions => [qw[Art MenuBar Help]],
);

my $plug = $app->GetExt('Help');

@tests = (
	[sub { return $plug->Name eq 'Help' }, 1, 'plugin Help loaded']
);

$app->MainLoop;

