package Tk::AppWindow::BaseClasses::PanelExtension;

=head1 NAME

Tk::AppWindow::Plugins::Bars - Basic functionality for esxtensions associated with a panel, like StatusBar and ToolBar

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

	$self->Require('Panels');
	$self->{VISIBLE} = 1;
	$self->{CONFIGMODE} = 1;

	$self->AddPostConfig('PostConfig', $self);
	return $self;
}

=head1 METHODS

=cut

sub Panel {
	my $self = shift;
	if (@_) { $self->{PANEL} = shift; }
	return $self->{PANEL};
}

sub PanelVisible {
	my $self = shift;
	return $self->{VISIBLE} unless exists $self->{CONFIGMODE};
	my $panels = $self->GetExt('Panels');
	if (@_) {
		my $status = shift;
		my $panel = $self->{PANEL};
		if ($status eq 1) {
			$panels->Show($panel);
			$self->{VISIBLE} = 1;
		} elsif ($status eq 0) {
			$panels->Hide($panel);
			$self->{VISIBLE} = 0;
		}
	}
	return $self->{VISIBLE}
}

sub PostConfig {
	delete $_[0]->{CONFIGMODE}
}
1;
