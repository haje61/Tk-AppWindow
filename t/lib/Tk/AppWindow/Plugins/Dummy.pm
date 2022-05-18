package Tk::AppWindow::Plugins::Dummy;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);


	return $self;
}

1;
 
