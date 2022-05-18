
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Tk::AppWindow::BaseClasses::Callback') };

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

sub Blabber {
	my $par = shift;
	return "Caterpillar$par";
}

my $blob = Blobber->new;

my $callback1 = Tk::AppWindow::BaseClasses::Callback->new('Get', $blob, 12);
ok(defined $callback1, "oo can create");

ok(($callback1->Anonymous eq 0), "Anonymous not set");

my $val1 = $callback1->Execute;
ok(($val1 eq "Butterfly12"), "oo execute without parameter");

my $val2 = $callback1->Execute(60);
ok(($val2 eq "Butterfly60"), "oo execute with parameter");

my $callback2 = Tk::AppWindow::BaseClasses::Callback->new(\&Blabber, 12);
ok(defined $callback2, "ann sub can create");

ok(($callback2->Anonymous eq 1), "Anonymous set");

my $val3 = $callback2->Execute;
ok(($val3 eq "Caterpillar12"), "ann sub execute without parameter");

my $val4 = $callback2->Execute(60);
ok(($val4 eq "Caterpillar60"), "ann sub execute with parameter");



