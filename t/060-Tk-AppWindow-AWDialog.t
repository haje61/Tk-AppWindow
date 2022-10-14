
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Tk;

use Test::More tests => 4;
BEGIN { use_ok('Tk::YADialog') };


CreateTestApp(
);

my $dialog = $app->YADialog(
	-buttons => ['Close'],
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


