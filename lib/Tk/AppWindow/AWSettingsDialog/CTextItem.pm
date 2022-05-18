package Tk::AppWindow::AWSettingsDialog::CTextItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CBooleanItem);
Construct Tk::Widget 'CTextItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
		DEFAULT => ['SELF'],
	);
}

sub EntryUpdate {
	my $self = shift;
	if ($self->Validate) {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('Entry')->configure(-foreground => $self->Plugin->ConfigGet('-errorcolor'));
	}
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $e = $self->Entry(
		-textvariable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

1;
