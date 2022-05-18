
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 13;
BEGIN { 
	use_ok('Tk::AppWindow::Plugins::StatusBar::SBaseItem');
	use_ok('Tk::AppWindow::Plugins::StatusBar::SImageItem');
	use_ok('Tk::AppWindow::Plugins::StatusBar::SMessageItem');
	use_ok('Tk::AppWindow::Plugins::StatusBar::SProgressItem');
	use_ok('Tk::AppWindow::Plugins::StatusBar::STextItem');
	use_ok('Tk::AppWindow::Plugins::StatusBar');
};


CreateTestApp(
	-plugins => [qw[Art Balloon StatusBar]],
);

my $plug = $app->GetPlugin('StatusBar');
my $bl = $plug->GetPlugin('Balloon');

my @padding = (-side => 'left', -padx => 10, -pady => 10);
my $ws = $app->WorkSpace;
my $black = $ws->Button(
	-text => 'Message',
	-command => sub { $plug->Message('Oh, gosh, I hope I don\'t fall in love today') },
)->pack(@padding);

my $red = $ws->Button(
	-text => 'Message in Red',
	-command => sub { $plug->Message('Oh, gosh, I hope I don\'t fall in love today', 'red') },
)->pack(@padding);

my $blue = $ws->Button(
	-text => 'Message in Blue',
	-command => sub { $plug->Message('Oh, gosh, I hope I don\'t fall in love today', 'blue') },
)->pack(@padding);

my $boole = 1;
$plug->AddImageItem(
	-label => 'Image',
	-updatecommand => sub {
		if ($boole) { $boole = 0 } else { $boole = 1 }
		return $boole
	}
);

my $num = 0;
$plug->AddTextItem(
	-label => 'Text',
	-updatecommand => sub {
		my $old = $num;
		$num++;
		if ($num eq 10) { $num = 0 }
		return $old
	}
);

my $prog = 0;
$plug->AddProgressItem(
	-label => 'Progress',
	-updatecommand => sub {
		my $old = $prog;
		$prog = $prog + 10;
		if ($prog eq 110) { $prog = 0 }
		return $old
	}
);

print "0: ", ref $plug->{ITEMS}->[0], "\n";
print "1: ", ref $plug->{ITEMS}->[1], "\n";
print "2: ", ref $plug->{ITEMS}->[2], "\n";
print "3: ", ref $plug->{ITEMS}->[3], "\n";

@tests = (
	[sub { return $plug->Name eq 'StatusBar' }, 1, 'plugin StatusBar loaded'],
	[sub { return ref $plug->{MI} }, 'Tk::AppWindow::Plugins::StatusBar::SMessageItem', 'message item loaded'],
	[sub { return ref $plug->{ITEMS}->[1] }, 'Tk::AppWindow::Plugins::StatusBar::SImageItem', 'image item loaded'],
	[sub { return ref $plug->{ITEMS}->[2] }, 'Tk::AppWindow::Plugins::StatusBar::STextItem', 'text item loaded'],
	[sub { return ref $plug->{ITEMS}->[3] }, 'Tk::AppWindow::Plugins::StatusBar::SProgressItem', 'progress item loaded'],
);

$app->MainLoop;

