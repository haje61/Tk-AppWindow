package Tk::AppWindow::Ext::ToolPanel;

=head1 NAME

Tk::AppWindow::Ext::Navigator - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

require Tk::YANoteBook;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ToolPanel'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a tool panel to your application.

Appends an item to the View menu to toggle visibility

=head1 CONFIG VARIABLES

=over 4

=item B<-toolpanel>

Default value 'RIGHT'. Sets the name of the panel home to B<Navigator>.

=item B<-toolpaneliconsize>

Default value 32.

=item B<-toolpanelvisible>

Default value 1. Show or hide navigator panel.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->addPreConfig(
		-toolpaneliconsize => ['PASSIVE', 'ToolPanelIconSize', 'toolPanelIconSize', 32],
	);

	$self->configInit(
		-toolpanel => ['Panel', $self, 'RIGHT'],
		-toolpanelvisible	=> ['PanelVisible', $self, 1],
	);
	my $nb = $self->Subwidget($self->Panel)->YANoteBook(
		-tabside => 'right',
	)->pack(-expand => 1, -fill=> 'both');
	$self->Advertise('TOOLNB', $nb);

	return $self;
}

=head1 METHODS

=over 4

=cut

sub addPage {
	my ($self, $name, $image, $text) = @_;
	my $nb = $self->Subwidget('NAVNB');

	my @opt = ();
	my $icon = $self->getArt($image, $self->configGet('-toolpaneliconsize'));
	@opt = (-titleimg => $icon) if defined $icon;
	my $page = $nb->addPage($name, @opt);
	my $balloon = $self->extGet('Balloon');
	my $l = $nb->getTab($name)->Subwidget('Label');
	$balloon->Attach($l, -balloonmsg => $text) if (defined $balloon) and (defined $icon);
	return $page;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label			Icon		config variable	off on
		[	'menu_check',		'View::',		"Show ~tool panel",	undef,	'-toolpanelvisible',	0,   1], 
	)
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
