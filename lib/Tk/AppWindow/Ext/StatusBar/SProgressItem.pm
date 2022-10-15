package Tk::AppWindow::Ext::StatusBar::SProgressItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::AppWindow::Ext::StatusBar::SBaseItem);
Construct Tk::Widget 'SProgressItem';
require Tk::ProgressBar;

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	my $t = $self->ProgressBar->pack($self->ItemPack);
	$self->Advertise('value', $t);
	$self->ConfigSpecs(
		-borderwidth => ['SELF'],
		-relief => ['SELF'],
		DEFAULT => [$t],
	);
}

sub Update {
	my $self = shift;
	$self->configure(-value => $self->Callback(-updatecommand => $self));
}

1;
