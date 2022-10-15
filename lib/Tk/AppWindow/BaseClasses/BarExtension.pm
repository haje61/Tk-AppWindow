package Tk::AppWindow::BaseClasses::BarExtension;

=head1 NAME

Tk::AppWindow::Plugins::Bars - Basic functionality for StatusBar and ToolBar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=back

=cut
sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('Bars');
	$self->{VISIBLE} = 1;
	$self->{POSITION} = undef;


	return $self;
}

=head1 METHODS

=cut

sub Bar {
	my $self = shift;
	if (@_) { $self->{BAR} = shift; }
	return $self->{BAR};
}

sub BarVisible {
	my $self = shift;
	my $bars = $self->GetExt('Bars');
	if (@_) {
		my $status = shift;
		if ($status eq 1) {
			$bars->Show($self->Position);
			$self->{VISIBLE} = 1;
		} elsif ($status eq 0) {
			$bars->Hide($self->Position);
			$self->{VISIBLE} = 0;
		}
	}
	return $self->{VISIBLE}
}

sub PackInfo {
	my $self = shift;
	if (@_) { $self->{PACKINFO} = shift }
	return $self->{PACKINFO}
}

sub Position {
	my $self = shift;
	if (@_) { $self->{POSITION} = shift }
	return $self->{POSITION}
}
1;
