package TestTextManager;

use Tk;
use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'TestTextManager';
require Tk::TextUndo;

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $text = $self->Scrolled('TextUndo',
	)->pack(-expand => 1, -fill => 'both');
	$self->{T} = $text;

	$self->ConfigSpecs(
		-background => [$text],
		DEFAULT => ['SELF',],
	);
}

sub doClear {
	my $self = shift;
	my $t = $self->{T};
	$t->delete('0.0', 'end');
	$t->editReset;
}

sub doLoad {
	my ($self, $file) = @_;
	my $t = $self->{T};
	$self->{T}->Load($file);
	$t->editModified(0);
	return 1
}

sub doSave {
	my ($self, $file) = @_;
	my $t = $self->{T};
	$t->Save($file);
	$t->editModified(0);
	return 1
}

sub Focus {
	my $self = shift;
	$self->{T}->focus;
}

sub IsModified {
	my $self = shift;
	return $self->{T}->editModified;	
}

1;
