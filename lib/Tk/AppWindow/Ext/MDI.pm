package Tk::AppWindow::Ext::MDI;

=head1 NAME

Tk::AppWindow::Ext::MDI - multiple document interface

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::Ext::SDI );

require Tk::YANoteBook;
use File::Basename;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a multi document interface to your application,
Inherites L<Tk::AppWindow::Ext::SDI>.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-maxtablength>

Default value 16

Maximum size of the document tab in the document bar.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->AddPreConfig(
		-maxtablength => ['PASSIVE', undef, undef, 16],
	);

	$self->AddPostConfig('CreateInterface', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<CmdFileClose>I(?$name?);

Closes $name. returns 1 if succesfull.
if $name is not specified closes the current document.

=cut

sub CmdFileClose {
	my ($self, $name) =  @_;
	my $doc;
	if (defined $name) {
		$doc = $self->GetDoc($name);
	} else {
		$name = $self->Current;
		$doc = $self->CurDoc;
	}
	return 1 unless (defined $doc);
	my $geosave = $self->geometry;
	if ($self->Interface->deletePage($name)) {
		$self->geometry($geosave);
		return 1;
	}
	return 0
}

=item B<CmdFileNew>I(?$name?);

Initiates a new content handler for $name.
If $name is not specified it creates and untitled document.

=cut

sub CmdFileNew {
	my ($self, $name) = @_;
	$name = $self->GetUntitled unless defined $name;
	my $cm = $self->CreateContentHandler($name);
	if (defined $cm) {
		#add to navigator
		my $navigator = $self->GetExt('Navigator');
		$navigator->Add($name) if defined $navigator;

		$self->Interface->selectPage($name);
		return 1;
	}
	return 0
}

=item B<CreateContentHandler>I($name);

Initiates a new content handler for $name.

=cut

sub CreateContentHandler {
	my ($self, $name) = @_;
	return undef if $self->DocExists($name);
	my $cmclass = $self->configGet('-contentmanagerclass');
	my @op = ();
	my $cti = $self->GetArt('tab-close', 16);
	push @op, -closeimage => $cti if defined $cti;
	my $page = $self->Interface->addPage($name, @op,
		-title => $self->GetTitle($name),
		-closebutton => 1,
	);
	my $h = $page->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
	$self->{DOCS}->{$name} = $h;
	return $h;
}

=item B<CreateInterface>

Creates a Tk::YANoteBook multiple document interface.

=cut

sub CreateInterface {
	my $self = shift;
	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
		-selecttabcall => ['Select', $self],
		-closetabcall => ['CloseDoc', $self],
	)->pack(-expand => 1, -fill => 'both');
}

=item B<Interface>

Returns a reference to the multiple document interface.

=cut

sub Interface {
	return $_[0]->{INTERFACE}
}

=item B<MenuItems>

Returns the menu items for MDI. Called by extension B<MenuBar>.

=cut

sub MenuItems {
	my $self = shift;
	return ($self->SUPER::MenuItems,
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
		[	'menu_normal',		'File::f2',		"S~ave all",			'file_save_all',		'document-save',	'CTRL+L'	], 
	)
}

sub RenameDoc {
	my ($self, $old, $new) = @_;
	$self->SUPER::RenameDoc($old, $new);
	my $i = $self->Interface;
	$i->renamePage($old, $new);
	my $tab = $i->GetTab($new);
	$tab->configure(
		-name => $new,
		-title => $self->GetTitle($new),
	);
}

sub Select {
	my ($self, $name) = @_;
	$self->Interface->selectPage($name);
	$self->SelectDoc($name);
	$self->{DOCS}->{$name}->Focus;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
