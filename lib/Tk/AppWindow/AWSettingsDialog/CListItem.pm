package Tk::AppWindow::AWSettingsDialog::CListItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CTextItem);
Construct Tk::Widget 'CListItem';

require Tk::ListEntry;

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
	my $e = $self->ListEntry(
		-textvariable => $var,
		-values => $values,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 if $$var eq '';
	return $self->Subwidget('Entry')->Validate
}

1;
