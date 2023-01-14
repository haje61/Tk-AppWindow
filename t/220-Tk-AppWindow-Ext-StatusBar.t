
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 13;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::StatusBar::SBaseItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SImageItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SMessageItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::SProgressItem');
	use_ok('Tk::AppWindow::Ext::StatusBar::STextItem');
	use_ok('Tk::AppWindow::Ext::StatusBar');
};


CreateTestApp(
	-extensions => [qw[Art Balloon StatusBar MenuBar]],
);

my $plug = $app->GetExt('StatusBar');
my $bl = $app->GetExt('Balloon');

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
$plug->AddImageItem('image',
	-valueimages => {
		0 => 'network-disconnect',
		1 => 'network-connect',
	},
	-label => 'Image',
	-updatecommand => sub {
		if ($boole) { $boole = 0 } else { $boole = 1 }
		return $boole
	}
);

my $num = 0;
$plug->AddTextItem('text',
	-label => 'Text',
	-updatecommand => sub {
		my $old = $num;
		$num++;
		if ($num eq 10) { $num = 0 }
		return $old
	}
);

my $prog = 0;
$plug->AddProgressItem('progress',
	-label => 'Progress',
	-updatecommand => sub {
		my $old = $prog;
		$prog = $prog + 10;
		if ($prog eq 110) { $prog = 0 }
		return $old
	}
);

@tests = (
	[sub { return $plug->Name eq 'StatusBar' }, 1, 'plugin StatusBar loaded'],
	[sub { return ref $plug->{MI} }, 'Tk::AppWindow::Ext::StatusBar::SMessageItem', 'message item loaded'],
	[sub { return ref $plug->Item('image') }, 'Tk::AppWindow::Ext::StatusBar::SImageItem', 'image item loaded'],
	[sub { return ref $plug->Item('text') }, 'Tk::AppWindow::Ext::StatusBar::STextItem', 'text item loaded'],
	[sub { return ref $plug->Item('progress') }, 'Tk::AppWindow::Ext::StatusBar::SProgressItem', 'progress item loaded'],
);

$app->MainLoop;

