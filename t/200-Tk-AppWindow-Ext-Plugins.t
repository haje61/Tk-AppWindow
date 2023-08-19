
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';
# $delay = 1500;

use Test::More tests => 11;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Plugins');
};

require TestTextManager;

createapp(
	-appname => 'Plugins',
	-commands => [plusser => [sub {
		my $v = 2;
		return $v + shift if @_;
		return $v;
	}]],
	-extensions => [qw[Art Balloon MenuBar ToolBar Plugins]],
	-plugins => ['Test'],
);

my $ext;
if (defined $app) {
	$ext = $app->GetExt('Plugins');
	
	$app->Button(
		-width => 30,
		-text => 'Load',
		-command => sub {
			$ext->plugLoad('Test');
			$ext->plugGet('Test')->Quitter(1);
		}
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
	$app->Button(
		-text => 'Unload',
		-command => ['plugUnload', $ext, 'Test'],
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
}

@tests = (
	[sub { return $ext->Name }, 'Plugins', 'extension Plugins loaded'],
	[sub { return $ext->plugGet('Test')->Name }, 'Test', 'plugin Test loaded',],
	[sub { return $app->cmdExecute('plusser') }, 4, 'Hook loaded'],
	[sub { 
		$app->cmdExecute('quit'); 
		return 1 
	}, 1, 'still running'],
	[sub {
		$ext->plugUnload('Test');
		return $ext->plugGet('Test')->Name; 
	}, 'Test', 'plugin Test can not unload'],
	[sub { 
		$ext->plugGet('Test')->Quitter(1); 
		return 1
	}, 1, 'now can quit'],
	[sub {
		$ext->plugUnload('Test');
		return $ext->plugGet('Test'); 
	}, undef, 'plugin Test unloaded'],
	[sub { return $app->cmdExecute('plusser') }, 2, 'Hook unloaded'],
);

starttesting;
