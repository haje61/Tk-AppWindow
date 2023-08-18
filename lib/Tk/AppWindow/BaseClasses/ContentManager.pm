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
	
	my $ext = delete $args->{'-extension'};
	$self->SUPER::Populate($args);
	$self->{EXT} = $ext;

	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
	$self->after(1, ['ConfigureCM', $self]);
}

sub Close {
	my $self = shift;
	$self->doClear;
	return 1
}

sub ConfigureCM {
	my $self = shift;
	my $ext = $self->Extension;
	my $cmopt = $ext->configGet('-contentmanageroptions');
	for (@$cmopt) {
		my $val = $ext->configGet($_);
		$self->configure($_, $val) if ((defined $val) and ($val ne ''));
	}
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
	return 1
}

sub doSave {
	return 1
}

sub Extension {
   my $self = shift;
   if (@_) { $self->{EXT} = shift; }
   return $self->{EXT};
}

sub Focus {
}

sub IsModified {
	my $self = shift;
	return 0
}

sub Load {
	my ($self, $file) = @_;
	return $self->doLoad($file);
}

sub Save {
	my ($self, $file) = @_;
	return $self->doSave($file);
}

1;
