
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;
use Tk;

use Test::More tests => 3;
BEGIN { use_ok('Tk::TabbedForm') };


CreateTestApp(
);

@tests = (
);

$app->MainLoop;


