package Tk::AppWindow::Plugins::StatusBar::SMessageItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::AppWindow::Plugins::StatusBar::STextItem);
Construct Tk::Widget 'SMessageItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->{COLORBCK} = $self->cget('-foreground');
	$self->toplevel->bind('<Any-KeyPress>', sub { $self->Clear });
	$self->toplevel->bind('<Button-1>', sub { $self->Clear });
}

=head1 METHODS

=cut

sub Clear {
	$_[0]->configure(
		-text => '',
		-foreground => $_[0]->{COLORBCK},
	);
}

sub Message {
	my ($self, $message, $color) = @_;
	$color = $self->{COLORBCK} unless defined $color;
	$self->configure(
		-text => $message,
		-foreground => $color,
	);
}

sub Remove {
	my $self = shift;
	$self->toplevel->bindRelease('<Any-KeyPress>');
	$self->toplevel->bindRelease('<Button-1>');
	$self->SUPER::Remove;
}

sub Update {}

1;
