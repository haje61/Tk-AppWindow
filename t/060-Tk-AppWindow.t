
use strict;
use warnings;
use lib './t/lib';
use Tk;

use Test::Tk;
use Test::More tests => 26;
$mwclass = 'Tk::AppWindow';

BEGIN { use_ok('Tk::AppWindow') };

package Blobber;
	
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		BLOBVAL => "Butterfly",
		AFTER => 0,
		BEFORE => 0,
	};
	bless ($self, $class);
}

sub After {
	return $_[0]->{AFTER}
}

sub Before {
	return $_[0]->{BEFORE}
}

sub Clear {
	my $self = shift;
	$self->{AFTER} = 0;
	$self->{BEFORE} = 0;
}

sub Get {
	my ($self, $par) = @_;
	return $self->{BLOBVAL} . $par
}

sub HitAfter {
	$_[0]->{AFTER} = 1
}

sub HitBefore {
	$_[0]->{BEFORE} = 1
}

sub Report {
	my $self = shift;
	return [ $self->After, $self->Before ]
}

package main;

my $blobber = Blobber->new;

createapp(
	-commands => [
		test1 => [\&Blabber, 12],
		test2 => ['Get', $blobber, 35],
	],
	-extensions => ['TestPlugin'],
	-quitter => 0,
);

#testing accessors
testaccessors($app, qw/AppName Verbose/);

push @tests, (
	[sub { return $app->cmdExecute('test1') }, 'Caterpillar12', 'anonymous command without parameter'],
	[sub { return $app->cmdExecute('test1', 60) }, 'Caterpillar60', 'anonymous command with parameter'],
	[sub { return $app->cmdExecute('test2') }, 'Butterfly35', 'object command without parameter'],
	[sub { return $app->cmdExecute('test2', 76) }, 'Butterfly76', 'object command with parameter'],
	[sub { return $app->GetExt('TestPlugin')->Name }, 'TestPlugin', 'TestPlugin loaded'],
	[sub { return $app->GetExt('Dummy')->Name }, 'Dummy', 'Dummy plugin loaded'],
	[sub { return $app->cmdExecute('plugcmd') }, 'TestCmd56', 'plugin command without parameter'],
	[sub { return $app->cmdExecute('plugcmd', 84) }, 'TestCmd84', 'plugin command with parameter'],
	[sub { return $app->configGet('-plugoption') }, 'Romulus', 'plugin option loaded'],
	[sub {
		$app->configPut(-plugoption => 'Vulcan');
		return $app->configGet('-plugoption') }, 'Vulcan', 'plugin option modified'],
	[sub { $app->cmdExecute('quit'); return 1 }, 1, 'still running'],
	[sub { $app->configPut('-quitter', 1); return 1 }, 1, 'terminated unless show option'],
	[sub {
		$app->cmdConfig(testcommand => ['Report', $blobber]);
		return $app->cmdExecute('testcommand');
	}, [0, 0], 'creating testcommand'],
	[sub {
		$app->cmdHookBefore('testcommand' ,'HitBefore', $blobber);
		my $call = $app->CmdGet('testcommand');
		my $h = $call->{HOOKSBEFORE};
		my $size = @$h;
		return $size;
	}, 1, 'adding hook before'],
	[sub {
		$app->cmdExecute('testcommand');
		return $blobber->Report;
	}, [0, 1], 'execute before'],
	[sub {
		$app->cmdHookAfter('testcommand', 'HitAfter', $blobber);
		my $call = $app->CmdGet('testcommand');
		my $h = $call->{HOOKSAFTER};
		my $size = @$h;
		return $size;
	}, 1, 'adding hook after'],
	[sub {
		$app->cmdExecute('testcommand');
		return $blobber->Report;
	}, [1, 1], 'execute after'],
	[sub {
		$blobber->Clear;
		$app->cmdUnhookBefore('testcommand' ,'HitBefore', $blobber);
		my $call = $app->CmdGet('testcommand');
		my $h = $call->{HOOKSBEFORE};
		my $size = @$h;
		return $size;
	}, 0, 'removing hook before'],
	[sub {
		$app->cmdExecute('testcommand');
		return $blobber->Report;
	}, [1, 0], 'execute'],
	[sub {
		$blobber->Clear;
		$app->cmdUnhookAfter('testcommand', 'HitAfter', $blobber);
		my $call = $app->CmdGet('testcommand');
		my $h = $call->{HOOKSAFTER};
		my $size = @$h;
		return $size;
	}, 0, 'removing hook after'],
	[sub {
		$app->cmdExecute('testcommand');
		return $blobber->Report;
	}, [0, 0], 'execute'],
);

starttesting;

sub Blabber {
	my $par = shift;
	return "Caterpillar$par";
}

