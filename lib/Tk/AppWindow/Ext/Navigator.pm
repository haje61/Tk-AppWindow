package Tk::AppWindow::Ext::Navigator;

=head1 NAME

Tk::AppWindow::Ext::Navigator - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

require Tk::YANoteBook;
require Tk::DocumentTree;

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

	$self->AddPreConfig(
		-documentinterface => ['PASSIVE', undef, undef, 'MDI'],
	);

	$self->ConfigInit(
		-navigatorpanel => ['Panel', $self, 'LEFT'],
		-navigatorvisible	=> ['PanelVisible', $self, 1],
	);
	
	my $nb = $self->Subwidget($self->Panel)->YANoteBook(
	)->pack(-expand => 1, -fill=> 'both');
	my $page = $nb->AddPage('Documents');
	my $dt = $page->DocumentTree(
		-entryselect => ['SelectDocument', $self],
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('TREE', $dt);

	return $self;
}

=head1 METHODS

=cut

sub Add {
	my ($self, $name) = @_;
	$self->Subwidget('TREE')->EntryAdd($name);
}

sub Delete {
	my ($self, $name) = @_;
	$self->Subwidget('TREE')->EntryDelete($name);
}

sub SelectDocument {
	my ($self, $name) = @_;
	my $di = $self->ConfigGet('-documentinterface');
	my $interface = $self->GetExt($di);
	$interface->Select($name);
}

sub SelectEntry {
	my ($self, $name) = @_;
	$self->Subwidget('TREE')->EntrySelect($name);
}

1;
