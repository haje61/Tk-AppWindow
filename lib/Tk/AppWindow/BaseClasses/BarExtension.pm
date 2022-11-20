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
	$self->{CONFIGMODE} = 1;

	$self->AddPostConfig('PostConfig', $self);
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
	return $self->{VISIBLE} unless exists $self->{CONFIGMODE};
	my $bars = $self->GetExt('Bars');
	if (@_) {
		my $status = shift;
		if ($status eq 1) {
			my $bar = $self->Bar;
			print "Bar $bar\n";
			$bars->Show($self->Bar);
			$self->{VISIBLE} = 1;
		} elsif ($status eq 0) {
			$bars->Hide($self->Bar);
			$self->{VISIBLE} = 0;
		}
	}
	return $self->{VISIBLE}
}

sub PostConfig {
	delete $_[0]->{CONFIGMODE}
}
1;
