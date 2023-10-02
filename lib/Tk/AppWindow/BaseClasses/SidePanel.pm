package Tk::AppWindow::BaseClasses::SidePanel;

=head1 NAME

Tk::AppWindow::Baseclasses::SidePanel - Basic functionality for esxtensions associated with a side panel, like Navigator and ToolPanel.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::YANoteBook;

use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

=head1 SYNOPSIS

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::SidePanel->new($frame);

 #This is what you should do
 package Tk::AppWindow::Ext::MyExtension
 use base(Tk::AppWindow::BaseClasses::SidePanel);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{TABSIDE} = 'top';
	$self->{LASTSIZE} = {};
	$self->{ICONSIZE} = 32;
	$self->addPostConfig('CreateNoteBook', $self);
	return $self;
}



=head1 METHODS

=over 4

=cut

sub addPage {
	my ($self, $name, $image, $text) = @_;
	$text = $name, unless defined $text;
	my $nb = $self->nbGet;

	my @opt = ();
	my $icon = $self->getArt($image, $self->IconSize);
	@opt = (-titleimg => $icon) if defined $icon;
	@opt = (-title => $text) unless defined $icon;
	my $page = $nb->addPage($name, @opt);

	my $balloon = $self->extGet('Balloon');
	my $l = $nb->getTab($name)->Subwidget('Label');
	$balloon->Attach($l, -balloonmsg => $text) if (defined $balloon) and (defined $icon);
	$self->after(500, sub { $nb->UpdateTabs });

	return $page;
}

sub CreateNoteBook {
	my $self = shift;
	my $nb = $self->Subwidget($self->Panel)->YANoteBook(
# 		-borderwidth => 4,
# 		-relief => 'groove',
		-onlyselect => 0,
		-rigid => 0,
		-selecttabcall => ['TabSelect', $self],
		-tabside => $self->Tabside,
		-unselecttabcall => ['TabUnselect', $self],
	)->pack(-expand => 1, -fill=> 'both', -padx => 2, -pady => 2);
	$self->geoAddCall($self->Panel, 'OnResize', $self);
	$self->Advertise($self->Name . 'NB', $nb);
# 	$self->after(250, sub { $nb->UpdateTabs });
	my $pn = $self->extGet('Panels');
	$pn->adjusterWidget($self->Panel, $nb);
	$pn->adjusterActive($self->Panel, 0);
# 	$self->TabUnselect;
}

sub deletePage {
	my ($self, $name) = @_;
	$self->nbGet->deletePage($name);
}

sub IconSize {
	my $self = shift;
	$self->{ICONSIZE} = shift if @_;
	return $self->{ICONSIZE};
}

sub nbGet {
	my $self = shift;
	return $self->Subwidget($self->Name . 'NB');
}

sub nbMaximize {
	my ($self, $tab) = @_;
	my $nb = $self->nbGet;
	my $pf = $nb->Subwidget('PageFrame');
	my $tf = $nb->Subwidget('TabFrame');
	my $panel = $self->Subwidget($self->Panel);
	my $offset = $self->nbOffset;
	my $height = $panel->height;;
	my $width = $panel->width;
	my $ls = $self->{LASTSIZE}->{$tab};
	my $ts = $self->Tabside;
	if (defined $ls) {
		my ($w, $h) = @$ls;
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = $h
		} else {
			$width = $w
		}
# 		print "saved size $width, $height\n";
	} else {
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = $nb->height + $offset + $pf->reqheight;
		} else {
			$width = $nb->width + $offset + $pf->reqwidth;
		}
# 		print "orignal size $width, $height\n";
	}
	$nb->GeometryRequest($width, $height);
}

sub nbMinimize {
	my ($self, $tab) = @_;
	my $nb = $self->nbGet;
	my $tf = $nb->Subwidget('TabFrame');
	$self->{LASTSIZE}->{$tab} = [$nb->width, $nb->height];
	my $ts = $self->Tabside;
	my $offset = $self->nbOffset;
	my @size = ();
	if (($ts eq 'top') or ($ts eq 'bottom')) {
		@size = ($nb->width + $offset, $tf->height + $offset);
	} else {
		@size = ($tf->width + $offset, $nb->height + $offset);
	}
	$nb->GeometryRequest(@size);
}

sub nbOffset {
	my $self = shift;
	my $nb = $self->nbGet;
	my $tf = $nb->Subwidget('TabFrame');
	return (($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2) +1
}

sub OnResize {
	my $self = shift;
	my $nb = $self->nbGet;
	my $panel = $self->Subwidget($self->Panel);

	my $owidth = $nb->width;
	my $oheight = $nb->height;
	my $offset = $self->panelOffset;
	my $width = $panel->width - $offset;
	my $height = $panel->height - $offset;
	
	$nb->GeometryRequest($width, $height) if ($width ne $owidth) or ($height ne $oheight);
# 	print "Resize\n";
}

sub panelOffset {
	my $self = shift;
	my $nb = $self->nbGet;
	my $border = $nb->cget('-borderwidth');
	my $pad = 0;
	my %pi = $nb->packInfo;
	$pad = $pi{'-padx'} if exists $pi{'-padx'};
	$pad = $pi{'-pady'} if exists $pi{'-pady'};
	return ($border + $pad) * 2;
}

sub TabSelect {
	my ($self, $tab) = @_;
# 	print "Tab $tab\n";
	return if $self->configMode;
	$self->geoBlock(1);
	my $pn = $self->extGet('Panels');
	$self->after(1, sub {
		$self->nbMaximize($tab);
		$pn->adjusterSet($self->Panel);
		$pn->adjusterActive($self->Panel, 1);
	});
	$self->after(200, ['geoBlock', $self, 0]);
}

sub Tabside {
	my $self = shift;
	$self->{TABSIDE} = shift if @_;
	return $self->{TABSIDE};
}

sub TabUnselect {
	my ($self, $tab) = @_;
	return if $self->configMode;
	my $pn = $self->extGet('Panels');
	$pn->adjusterClear($self->Panel);
	$pn->adjusterActive($self->Panel, 0);
	$self->geoBlock(1);
	$self->nbMinimize($tab);
	$self->after(400, ['geoBlock', $self, 0]);
# 	$self->Subwidget($self->Panel)->GeometryRequest(@size);
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
__END__



