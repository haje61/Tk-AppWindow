package Tk::AppWindow::Ext::Bars;

=head1 NAME

Tk::AppWindow::Plugins::Bars - Make room for toolbars and side panels

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Adjuster;

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

	my $args = $self->GetArgsRef;
	my $fullbar = delete $args->{-fullsizebars};
	$fullbar = 'vertical' unless defined $fullbar;

	$self->ConfigInit(
		-barsizers => ['BarSizers', $self, [qw[LEFT RIGHT]]],
	);

	my $app = $self->GetAppWindow;

	my $center;
	my $work;
	my $top;
	my $bottom;
	my $left;
	my $right;
	
	my %packinfo = ();

	if ($fullbar eq 'horizontal') {
		$center = $app->Frame->pack(-side => 'top', -expand => 1, -fill => 'both');
		$work = $center->Frame->pack(-side => 'left', -expand => 1, -fill => 'both');
		$top = $app->Frame;
		$bottom = $app->Frame;
		$left = $center->Frame;
		$right = $center->Frame;
		%packinfo = (
			TOP => {
				-side => 'top',
				-before => $center,
				-fill => 'x',
			},
			BOTTOM => {
				-after => $center,
				-side => 'top',
				-fill => 'x',
			},
			LEFT => {
				-before => $work,
				-side => 'left',
				-fill => 'y',
			},
			RIGHT => {
				-after => $work,
				-side => 'left',
				-fill => 'y',
			},
		);
	} else {
		$center = $app->Frame->pack(-side => 'left', -expand => 1, -fill => 'both');
		$work = $center->Frame->pack(-side => 'top', -expand => 1, -fill => 'both');
		$top = $center->Frame;
		$bottom = $center->Frame;
		$left = $app->Frame;
		$right = $app->Frame;
		%packinfo = (
			TOP => {
				-before => $work,
				-side => 'top',
				-fill => 'x',
			},
			BOTTOM => {
				-after => $work,
				-side => 'top',
				-fill => 'x',
			},
			LEFT => {
				-before => $center,
				-side => 'left',
				-fill => 'y',
			},
			RIGHT => {
				-after => $center,
				-side => 'left',
				-fill => 'y',
			},
		)
	}

	$app->Advertise(TOP => $top);
	$app->Advertise(BOTTOM => $bottom);
	$app->Advertise(LEFT => $left);
	$app->Advertise(RIGHT => $right);
	$app->Advertise(CENTER => $center);
	$app->Advertise(WORK => $work);
	$app->WorkSpace($work);

	$self->{ADJUSTERS} = {};
	$self->{PACKINFO} = \%packinfo;

	return $self;
}

=head1 METHODS

=cut

sub BarSizers {
	my $self = shift;
	if (@_) { $self->{BARSIZERS} = shift; }
	return $self->{BARSIZERS}
}

sub Hide {
	my ($self, $bar) = @_;
	$self->Subwidget($bar)->packForget;
	my $adj = delete $self->{ADJUSTERS}->{$bar};
	$adj->destroy if defined $adj;
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
	my $b = $self->Subwidget($bar);
	my $pi = $self->{PACKINFO}->{$bar};

	$b->pack(%$pi);
	my $barsizers = $self->ConfigGet('-barsizers');
	my @i = grep { $barsizers->[$_] eq $bar } (0 .. @$barsizers-1);
	if (@i) {
		my $side = lc($bar);
		$side = 'top' unless defined $side;
# 		if ($side eq 'left') {
# 			$side = 'right'
# 		} elsif ($side eq 'right') {
# 			$side = 'left'
# 		} elsif ($side eq 'top') {
# 			$side = 'bottom'
# 		} elsif ($side eq 'bottom') {
# 			$side = 'top'
# 		}
		my $adj = $b->parent->Adjuster(
			-side => $side,
			-widget => $b,
		)->pack(%$pi);
		$self->{ADJUSTERS}->{$bar} = $adj;
	}
}

1;
