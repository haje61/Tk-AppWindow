use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::Bars') };


CreateTestApp(
	-extensions => [qw[Bars]],
	-barsizers => [qw[LEFT RIGHT TOP BOTTOM]],
# 	-barsizers => [qw[]],
# 	-fullsizebars => 'horizontal',
);
my $ext = $app->GetExt('Bars');

my %visible = ();
my $f = $app->Subwidget('WORK')->Frame(-relief => 'groove')->pack(-expand => 1, -fill => 'both');
for (qw[LEFT RIGHT TOP BOTTOM]) {
	my $bar = $_;
	my $t = $app->Subwidget($bar)->Label(-relief => 'groove', -text => $bar)->pack(-expand => 1, -fill => 'both');
	$ext->Show($bar);
	my $var = 1;
	$visible{$_} = \$var;
	$f->Checkbutton(
		-text => $_,
		-variable => \$var,
		-command => sub {
			my $vis = $visible{$bar};
			if ($$vis) {
				$ext->Show($bar);
			} else {
				$ext->Hide($bar);
			}
		}
	)->pack(-anchor => 'w');
}


@tests = (
	[sub { return $ext->Name eq 'Bars' }, 1, 'extension Bars loaded']
);

$app->MainLoop;
