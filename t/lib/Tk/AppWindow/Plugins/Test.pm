package Tk::AppWindow::Plugins::Test;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

my $plsub = sub { return 2 };

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{QUITTER} = 0;
	$self->cmdHookBefore('plusser', $plsub);
# 	$self->Require('Dummy');
	return $self;
}

sub CanQuit {
	my $self = shift;
	return $self->{QUITTER};
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,			"~Test"], 
		[	'menu_normal',		'Test::',		"~PopTest",				'poptest',				'help-about',	'CTRL+T'			], 
	)
}

sub ToolItems {
	return (
#	 type					label			cmd					icon					help		
		[	'tool_button',		'Test',	'poptest',		'help-about',	'Pop up a message'],
	)
}

sub Unload {
	my $self = shift;
	if ($self->{QUITTER}) {
		$self->cmdUnhookBefore('plusser', $plsub);
		return 1
	}
	return 0
}

sub Quitter {
	my ($self, $val) = @_;
	$self->{QUITTER} = $val;
}


1;
