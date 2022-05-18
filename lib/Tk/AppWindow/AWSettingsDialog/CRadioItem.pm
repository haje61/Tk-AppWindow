package Tk::AppWindow::AWSettingsDialog::CRadioItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CBooleanItem);
Construct Tk::Widget 'CRadioItem';

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	for (@$values) {
		$self->Radiobutton(
			-text => $_,
			-value => $_,
			-variable => $var,
		)->pack(-side => 'left', -padx => 2, -pady => 2);
	}
}

1;
