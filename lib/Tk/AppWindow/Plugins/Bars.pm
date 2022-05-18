package Tk::AppWindow::Plugins::Bars;

=head1 NAME

Tk::AppWindow::Plugins::Bars - Make room for toolbars and side panels

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

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

	my $app = $self->GetAppWindow;

	my $top = $app->Frame;
	$app->Advertise(TOP => $top);

	my $center = $app->Frame->pack(-expand => 1, -fill => 'both');
	$app->Advertise(CENTER => $center);

	my $bottom = $app->Frame;
	$app->Advertise(BOTTOM => $bottom);

	my $left = $center->Frame;
	$app->Advertise(LEFT => $left);

	my $work = $center->Frame->pack(-side => 'left', -expand => 1, -fill => 'both');
	$app->Advertise(WORK => $work);
	$app->WorkSpace($work);

	my $right = $center->Frame;
	$app->Advertise(RIGHT => $right);

	$self->{PACKINFO} = {
		TOP => [
			-before => $center,
			-fill => 'x',
		],
		BOTTOM => [
			-side => 'bottom',
			-fill => 'x',
		],
		LEFT => [
			-before => $work,
			-side => 'left',
			-fill => 'y',
		],
		RIGHT => [
			-side => 'right',
			-fill => 'y',
		],
	};

	return $self;
}

=head1 METHODS

=cut

sub Hide {
	my ($self, $bar) = @_;
	$self->Subwidget($bar)->packForget;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,			"~View"], 
	)
}

sub Show {
	my ($self, $bar) = @_;
	my $pi = $self->{PACKINFO}->{$bar};
	$self->Subwidget($bar)->pack(@$pi);
}

1;
