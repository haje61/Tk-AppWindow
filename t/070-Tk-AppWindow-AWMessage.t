use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Tk;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::AWMessage') };


CreateTestApp(
	-plugins => [qw[Art]],
);

my $dialog = $app->AWMessage(
	-text => "This is a loong looooong \nloooooong\n long longer\n longest message!",
	-image => $app->GetArt('dialog-information', 32),
	-defaultbutton => 'Ok',
);

@tests = (
	[sub {  
		if ($show) {

			return $dialog->Show(-popover => $app);
		} else {
			return 'Ok'
		}
	}, 'Ok', 'pressing a button']
);

$app->MainLoop;

