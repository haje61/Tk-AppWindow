package Tk::AppWindow::Ext::Panels;

=head1 NAME

Tk::AppWindow::Plugins::Panels - Manage the layout of your application

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

	$self->{PACKINFO} = {};
	$self->{ADJUSTERS} = {};

	$self->ConfigInit(
		-panellayout => ['PanelLayOut', $self, [
			CENTER => {
				-in => 'MAIN',
				-side => 'top',
				-fill => 'both',
				-expand => 1,
			},
			WORK => {
				-in => 'CENTER',
				-side => 'left',
				-fill => 'both',
				-expand => 1,
			},
			TOP => {
				-in => 'MAIN',
				-side => 'top',
				-before => 'CENTER',
				-fill => 'x',
				-canhide => 1,
			},
			BOTTOM => {
				-in => 'MAIN',
				-after => 'CENTER',
				-side => 'top',
				-fill => 'x',
				-canhide => 1,
			},
			LEFT => {
				-in => 'CENTER',
				-before => 'WORK',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-adjuster => 'left',
			},
			RIGHT => {
				-in => 'CENTER',
				-after => 'WORK',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-adjuster => 'right',
			},
		
		]],
		-workspace => ['WorkSpace', $self->GetAppWindow, 'WORK'],
	);


	return $self;
}

=head1 METHODS

=cut

sub Hide {
	my ($self, $panel) = @_;
	$self->Subwidget($panel)->packForget;
	if (exists $self->{ADJUSTERS}->{$panel}) {
		$self->{ADJUSTERS}->{$panel}->packForget;
	}
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,			"~View"], 
	)
}

sub PanelLayOut {
	my ($self, $layout) = @_;
	return unless defined $layout;
	my @l = @$layout;
	while (@l) {
		my $name = shift @l;
		my $options = shift @l;

		my $in = delete $options->{'-in'};
		die "Option -in must be specified" unless defined $in;
		
		my $canhide = delete $options->{'-canhide'};
		$canhide = 0 unless defined $canhide;

		my $parent;
		if ($in eq 'MAIN') {
			$parent = $self->GetAppWindow;
		} else {
			$parent = $self->Subwidget($in)
		}
		die "Panel $in does not exist" unless defined $parent;

		my $before = delete $options->{'-before'};
		if (defined $before) {
			my $neighbor = $self->Subwidget($before);
			die "Panel $neighbor does not exist" unless defined $neighbor;
			$options->{'-before'} = $neighbor;
		}

		my $after = delete $options->{'-after'};
		if (defined $after) {
			my $neighbor = $self->Subwidget($after);
			die "Panel $neighbor does not exist" unless defined $neighbor;
			$options->{'-after'} = $neighbor;
		}

		my $paneloptions = delete $options->{'-paneloptions'};
		$paneloptions = [] unless defined $paneloptions;

		my $panel = $parent->Frame(@$paneloptions);
		$self->Advertise($name, $panel);
		
		my $adjuster = delete $options->{'-adjuster'};
		my $adj;
		if (defined $adjuster) {
			$adj = $parent->Adjuster(
				-widget => $panel,
				-side => $adjuster,
			);
		}
		
		if ($canhide) {
			$self->{PACKINFO}->{$name} = $options;
			$self->{ADJUSTERS}->{$name} = $adj if defined $adj;
		} else {
			$panel->pack(%$options);
			$adj->pack(%$options) if defined $adj;
		}
	}
}

sub Show {
	my ($self, $name) = @_;
	my $panel = $self->Subwidget($name);
	my $packinfo = $self->{PACKINFO}->{$name};
	$panel->pack(%$packinfo);
	if (exists $self->{ADJUSTERS}->{$name}) {
		$self->{ADJUSTERS}->{$name}->pack(%$packinfo)
	}
}

1;
