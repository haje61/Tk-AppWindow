package Tk::AppWindow::Ext::MDI;

=head1 NAME

Tk::AppWindow::Ext::MDI - Multiple Document Interface

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
		-maxtablength => ['PASSIVE', undef, undef, 16],
	);

	$self->AddPostConfig('CreateInterface', $self);
	return $self;
}

=head1 METHODS

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

sub CreateContentHandler {
	my ($self, $name) = @_;
	return undef if $self->DocExists($name);
	my $cmclass = $self->ConfigGet('-contentmanagerclass');
	my $page = $self->Interface->AddPage($name,
		-title => $self->GetTitle($name),
		-closebutton => 1,
	);
	my $h = $page->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
	$self->{DOCS}->{$name} = $h;
	return $h;
}

sub CreateInterface {
	my $self = shift;
	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
		-selecttabcall => ['Select', $self],
		-closetabcall => ['CloseDoc', $self],
	)->pack(-expand => 1, -fill => 'both');
	
}

sub Interface {
	return $_[0]->{INTERFACE}
}

sub MenuItems {
	my $self = shift;
	return ($self->SUPER::MenuItems,
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
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
}

1;
