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

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=over 4

Adds a multi document interface to your application,
Inherites L<Tk::AppWindow::Ext::SDI>.

=back

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-maxtablength>

=over 4

Default value 16

Maximum size of the document tab in the document bar.

=back

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

=over 4

Closes $name. returns 1 if succesfull.
if $name is not specified closes the current document.

=back

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
	if ($self->Interface->DeletePage($name)) {
		$self->geometry($geosave);
		return 1;
	}
	return 0
}

=item B<CmdFileNew>I(?$name?);

=over 4

Initiates a new content handler for $name.
If $name is not specified it creates and untitled document.

=back

=cut

sub CmdFileNew {
	my ($self, $name) = @_;
	$name = $self->GetUntitled unless defined $name;
	my $cm = $self->CreateContentHandler($name);
	if (defined $cm) {
		#add to navigator
		my $navigator = $self->GetExt('Navigator');
		$navigator->Add($name) if defined $navigator;

		$self->Interface->SelectPage($name);
		return 1;
	}
	return 0
}

=item B<CreateContentHandler>I($name);

=over 4

Initiates a new content handler for $name.

=back

=cut

sub CreateContentHandler {
	my ($self, $name) = @_;
	return undef if $self->DocExists($name);
	my $cmclass = $self->ConfigGet('-contentmanagerclass');
	my @op = ();
	my $cti = $self->GetArt('tab-close', 16);
	push @op, -closeimage => $cti if defined $cti;
	my $page = $self->Interface->AddPage($name, @op,
		-title => $self->GetTitle($name),
		-closebutton => 1,
	);
	my $h = $page->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
	$self->{DOCS}->{$name} = $h;
	return $h;
}

=item B<CreateInterface>

=over 4

Creates a Tk::YANoteBook multiple document interface.

=back

=cut

sub CreateInterface {
	my $self = shift;
	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
		-selecttabcall => ['Select', $self],
		-closetabcall => ['CloseDoc', $self],
	)->pack(-expand => 1, -fill => 'both');
}

=item B<Interface>

=over 4

Returns the reference to the multiple document interface.

=back

=cut

sub Interface {
	return $_[0]->{INTERFACE}
}

=item B<MenuItems>

=over 4

Returns the menu items for MDI. Called by extension B<MenuBar>.

=back

=cut

sub MenuItems {
	my $self = shift;
	return ($self->SUPER::MenuItems,
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
		[	'menu_normal',		'File::f2',		"S~ave all",			'file_save_all',		'document-save',	'Control-l'	], 
	)
}

sub RenameDoc {
	my ($self, $old, $new) = @_;
	$self->SUPER::RenameDoc($old, $new);
	my $i = $self->Interface;
	$i->RenamePage($old, $new);
	my $tab = $i->GetTab($new);
	$tab->configure(
		-name => $new,
		-title => $self->GetTitle($new),
	);
}

sub Select {
	my ($self, $name) = @_;
	$self->Interface->SelectPage($name);
	$self->SelectDoc($name);
	$self->{DOCS}->{$name}->Focus;
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. If you find any, please contact the author.

=cut

=head1 TODO

=over 4


=back

=cut

=head1 SEE ALSO

=over 4


=back

=cut

1;
