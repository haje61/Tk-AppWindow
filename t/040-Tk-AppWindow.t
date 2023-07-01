
use strict;
use warnings;
use lib './t/lib';
use Tk;

use Test::Tk;
use Test::More tests => 15;
$mwclass = 'Tk::AppWindow';

BEGIN { use_ok('Tk::AppWindow') };

{
	package Blobber;
	
	use strict;
	
	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {
			BLOBVAL => "Butterfly"
		};
		bless ($self, $class);
	}
	
	sub Get {
		my ($self, $par) = @_;
		return $self->{BLOBVAL} . $par
	}
	
	1;
}

my $blobber = Blobber->new;

createapp(
	-commands => [
		test1 => [\&Blabber, 12],
		test2 => ['Get', $blobber, 35],
	],
	-extensions => ['TestPlugin'],
	-quitter => 0,
);

@tests = (
	[sub { return $app->CommandExecute('test1') }, 'Caterpillar12', 'anonymous command without parameter'],
	[sub { return $app->CommandExecute('test1', 60) }, 'Caterpillar60', 'anonymous command with parameter'],
	[sub { return $app->CommandExecute('test2') }, 'Butterfly35', 'object command without parameter'],
	[sub { return $app->CommandExecute('test2', 76) }, 'Butterfly76', 'object command with parameter'],
	[sub { return $app->GetExt('TestPlugin')->Name }, 'TestPlugin', 'TestPlugin loaded'],
	[sub { return $app->GetExt('Dummy')->Name }, 'Dummy', 'Dummy plugin loaded'],
	[sub { return $app->CommandExecute('plugcmd') }, 'TestCmd56', 'plugin command without parameter'],
	[sub { return $app->CommandExecute('plugcmd', 84) }, 'TestCmd84', 'plugin command with parameter'],
	[sub { return $app->ConfigGet('-plugoption') }, 'Romulus', 'plugin option loaded'],
	[sub {
		$app->ConfigPut(-plugoption => 'Vulcan');
		return $app->ConfigGet('-plugoption') }, 'Vulcan', 'plugin option modified'],
	[sub { $app->CommandExecute('quit'); return 1 }, 1, 'still running'],
	[sub { $app->ConfigPut('-quitter', 1); return 1 }, 1, 'terminated unless show option'], 
);

starttesting;

sub Blabber {
	my $par = shift;
	return "Caterpillar$par";
}

