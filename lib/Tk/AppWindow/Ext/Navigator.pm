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

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI', 'Navigator'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a navigation panel with a document list to your application.

Appends an item to the View menu to toggle visibility

=head1 CONFIG VARIABLES

=over 4

=item B<-documentinterface>

Default value 'MDI'. Sets the extension with witch B<Navigator> communicates.

=item B<-navigatorpanel>

Default value 'LEFT'. Sets the name of the panel home to B<Navigator>.

=item B<-navigatorvisible>

Default value 1. Show or hide navigator panel.

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
	$self->Advertise('NAVNB', $nb);

	my $page = $nb->addPage('Documents');
	my $dt = $page->DocumentTree(
		-entryselect => ['SelectDocument', $self],
		-diriconcall => ['GetDirIcon', $self],
		-fileiconcall => ['GetFileIcon', $self],
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('NAVTREE', $dt);
	$self->update;

	return $self;
}

=head1 METHODS

=over 4

=cut

sub Add {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entryAdd($name);
}

sub Delete {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entryDelete($name);
}

sub GetDirIcon {
	my ($self, $name) = @_;
	my $icon = $self->GetArt('folder', 16);
	return $icon if defined $icon;
	return $self->SubWidget('NAVTREE')->DefaultDirIcon;
}

sub GetFileIcon {
	my ($self, $name) = @_;
	my $icon = $self->GetArt('text-x-plain', 16);
	return $icon if defined $icon;
	return $self->SubWidget('NAVTREE')->DefaultFileIcon;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label			Icon		config variable	off on
		[	'menu_check',		'View::',		"Show ~navigation panel",	undef,	'-navigatorvisible',	0,   1], 
	)
}

sub SelectDocument {
	my ($self, $name) = @_;
	$self->GetExt($self->ConfigGet('-documentinterface'))->Select($name);
}

sub SelectEntry {
	my ($self, $name) = @_;
	$self->Subwidget('NAVTREE')->entrySelect($name);
}

=back

=head1 AUTHOR

=item Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
