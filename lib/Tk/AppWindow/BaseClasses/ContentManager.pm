package Tk::AppWindow::BaseClasses::ContentManager;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION="0.01";

use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'ContentManager';

use File::Basename;


sub Populate {
	my ($self,$args) = @_;
	
	my $plug = delete $args->{'-plugin'};
	$self->SUPER::Populate($args);
	$self->{PLUG} = $plug;

	$self->ConfigSpecs(
		-filename => ['PASSIVE', undef, undef, ''],
		-filestamp => ['PASSIVE', undef, undef, ''],
		DEFAULT => ['SELF'],
	);
	$self->after(1, ['Configure', $self]);
}

sub Close {
	my $self = shift;
	$self->configure( -filename => '');
	$self->doClear;
	return 1
}

sub Configure {
}

sub ConfigureBindings {
	my $self = shift;
	$self->{BINDINGS} = {@_}
}

sub CWidg {
	my $self = shift;
	$self->{WIDGET} = shift if @_;
	return $self->{WIDGET};
}

sub DiskModified {
	my $self = shift;
	return 0
}

sub doClear{
}

sub doLoad {
}

sub doSave {
}

sub IsModified {
	my $self = shift;
	return 0
}

sub Load {
	my $self = shift;
	my $file = $self->cget('-filename');
	$self->doLoad($file);
	return 1
}

sub Plug {
   my $self = shift;
   if (@_) { $self->{PLUG} = shift; }
   return $self->{PLUG};
}

sub Save {
	my $self = shift;
	my $file = $self->cget('-filename');
	$self->doSave($file);
	return 1
}

1;
