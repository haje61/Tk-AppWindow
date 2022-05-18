package Tk::AppWindow::Plugins::TestPlugin;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $w = $self->GetAppWindow;
	$w->AddPreConfig(
		#used for AppWindow.t
		-check_1 => ['PASSIVE', undef, undef, 'Amsterdam'],
		-check_2 => ['PASSIVE', undef, undef, 0],
		-check_3 => ['PASSIVE', undef, undef, 1],
		-radio_1 => ['PASSIVE', undef, undef, 'BLUE'],
		-radio_2 => ['PASSIVE', undef, undef, 'Spring'],
		-radio_3 => ['PASSIVE', undef, undef, 0],
		
		#used for Settings.t
		-set_boolean => ['PASSIVE', undef, undef, 0],
		-set_color => ['PASSIVE', undef, undef, '#0FE00F'],
		-set_file => ['PASSIVE', undef, undef, '~/.Xdefaults'],
		-set_float => ['PASSIVE', undef, undef, 0],
		-set_folder => ['PASSIVE', undef, undef, '~/Documents'],
		-set_font => ['PASSIVE', undef, undef, 'Hack 10'],
		-set_list_command => ['PASSIVE', undef, undef, 'Breeze'],
		-set_list_values => ['PASSIVE', undef, undef, 'Up'],
		-set_integer => ['PASSIVE', undef, undef, 0],
		-set_radio_command => ['PASSIVE', undef, undef, 22],
		-set_radio_values => ['PASSIVE', undef, undef, 'Medium'],
		-set_text => ['PASSIVE', undef, undef, 'This is a text'],
	);
	$self->{QUITTER} = 0;
	$self->{VALUE} = '';

	$self->Require('Dummy');

	$w->CommandsConfig(
		plugcmd => ['PlugTest', $self, 56],
	);
	
	$w->ConfigInit(
		-quitter => ['Quitter', $self, 1],
		-plugoption => ['Value', $self, 'Romulus' ],
	);
	return $self;
}

sub CanQuit {
	my $self = shift;
	return $self->{QUITTER};
}

sub PlugTest {
	my ($self, $par) = @_;
	return 'TestCmd' . $par
}

sub Quitter {
	my ($self, $val) = @_;
	$self->{QUITTER} = $val;
}

sub Value {
	my $self = shift;
	if (@_) { $self->{VALUE} = shift	}
	return $self->{VALUE}
}

1;
