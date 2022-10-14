
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Tk;

use Test::More tests => 4;
BEGIN { use_ok('Tk::YAColorDialog') };


CreateTestApp(
);

my $dialog = $app->YAColorDialog(
);

@tests = (
	[sub {  
		if ($show) {
			return $dialog->Show(-popover => $app);
		} else {
			return 'Close'
		}
	}, 'Close', 'pressing a button']
);

$app->MainLoop;


