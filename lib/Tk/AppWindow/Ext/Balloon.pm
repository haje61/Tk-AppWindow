package Tk::AppWindow::Ext::Balloon;

=head1 NAME

Tk::AppWindow::Plugins::FileCommands - a plugin for opening, saving and closing files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Balloon;

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
	$self->{BALLOON} = $self->GetAppWindow->Balloon;
	return $self;
}

=head1 METHODS

=cut

sub Attach {
	my $self = shift;
	$self->{BALLOON}->attach(@_);
}

sub Balloon {
	return $_[0]->{BALLOON}
}

1;
