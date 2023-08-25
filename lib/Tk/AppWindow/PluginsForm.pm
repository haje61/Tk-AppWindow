package Tk::AppWindow::PluginsForm;

=head1 NAME

Tk::AppWindow::PluginsForm - Load and unload plugins.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Tk::Derived Tk::Frame);

Construct Tk::Widget 'PluginsForm';

require Tk::LabFrame;
require Tk::Pane;

sub Populate {
	my ($self,$args) = @_;

	my $ext = delete $args->{'-pluginsext'};
	die 'Please specify -pluginsext' unless defined $ext;
	
	$self->SUPER::Populate($args);

	my $avail = $ext->configGet('-availableplugs');
	my $lf = $self->LabFrame(
		-label => 'Available plugins',
		-labelside => 'acrosstop',
	)->pack(-expand => 1, -fill => 'both', -padx => 2, -pady => 2);
	my $pane = $lf->Scrolled('Pane',
		-height => 200,
		-scrollbars => 'oe',
		-sticky => 'ns',
	)->pack(-expand => 1, -fill => 'both');
	for (@$avail) {
		my $plug = $_;
		my $val = $ext->plugExists($plug);
		my $f = $pane->Frame(
			-borderwidth => 2,
			-relief => 'groove',
		)->pack(-fill => 'x', -padx => 2, -pady => 2);
		$f->Checkbutton(
			-command => sub {
				if ($val) {
					$ext->plugLoad($plug);
				} else {
					$ext->plugUnload($plug);
				}
			},
			-variable => \$val,
			-text => $plug
		)->pack(-padx => 2, -pady => 2, -anchor => 'w');
		$f->Label(
			-text => $ext->plugDescription($plug),
			-justify => 'left',
		)->pack(-padx => 2, -pady => 2, -anchor => 'w');
		
	}
	my $bf = $self->Frame->pack(-fill => 'x');
	$bf->Button(
		-text => 'Load all',
		-command => ['LoadAll', $self],
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$bf->Button(
		-text => 'Unload all',
		-command => ['UnloadAll', $self],
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$self->ConfigSpecs(
		-pluginsext => ['PASSIVE', undef, undef, $ext],
		DEFAULT => [ $self ],
	);
}

sub LoadAll {
	my $self = shift;
	my $ext = $self->cget('-pluginsext');
	my $avail = $ext->configGet('-availableplugs');
	for (@$avail) { $ext->plugLoad($_); }
}

sub UnloadAll {
	my $self = shift;
	my $ext = $self->cget('-pluginsext');
	my $avail = $ext->configGet('-availableplugs');
	for (@$avail) { $ext->plugUnload($_); }
}

1;
