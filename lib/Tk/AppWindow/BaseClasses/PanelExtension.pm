package Tk::AppWindow::BaseClasses::PanelExtension;

=head1 NAME

Tk::AppWindow::Baseclasses::PanelExtension - Basic functionality for esxtensions associated with a panel, like StatusBar and ToolBar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

=over 4

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::PanelExtension->new($frame);

 #This is what you should do
 package Tk::AppWindow::Ext::MyExtension
 use base(Tk::AppWindow::BaseClasses::PanelExtension);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=back

=head1 DESCRIPTION

=over 4

=back

=head1 B<CONFIG VARIABLES>

=over 4

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('Panels');
	$self->{VISIBLE} = 1;

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
	my $panels = $self->GetExt('Panels');
	if (@_) {
		my $status = shift;
		my $panel = $self->{PANEL};
		if ($self->ConfigMode) {
		} elsif ($status eq 1) {
			$panels->Show($panel);
		} elsif ($status eq 0) {
			$panels->Hide($panel);
		}
		$self->{VISIBLE} = $status;
	}
	return $self->{VISIBLE}
}

sub PostConfig {
	my $self = shift;
	$self->PanelVisible($self->{VISIBLE});
}

;
