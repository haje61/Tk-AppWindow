package Tk::AppWindow::Plugins::Help;

=head1 NAME

Tk::AppWindow::Plugins::Help - a plugin with an about box and help facilities

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Plugin );

use Browser::Open qw(open_browser);
use Tk;
require Tk::AppWindow::AWDialog;
require Tk::NoteBook;
require Tk::ROText;
require Tk::Pod::Text;

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
		-aboutinfo => ['PASSIVE', undef, undef, {
			version => $VERSION,
			license => 'Same as Perl',
			author => 'Some Dude',
			http => 'www.nowhere.com',
			email => 'nobody@nowhere.com',
		}],
		-helptype => ['PASSIVE', undef, undef, 'pod'],
		-helpfile => ['PASSIVE', undef, undef, Tk::findINC('Tk/AppWindow.pm')],
	);

	$self->CommandsConfig(
		about => [\&CmdAbout, $self],
		help => [\&CmdHelp, $self],
	);
	return $self;
}

=head1 METHODS

=cut

sub CmdAbout {
	my $self = shift;
	my $inf = $self->ConfigGet('-aboutinfo');
	my $w = $self->GetAppWindow;
	my $db = $w->AWDialog(
		-buttons => ['Ok'],
		-defaultbutton => 'Ok',
		-title => 'About ' . $w->AppName,
	);
	$db->configure(-command => sub { $db->destroy });
	my @padding = (-padx => 2);
	my $ap;
	if (exists $inf->{licensefile}) {
		my $nb = $db-NoteBook->pack(-expand => 1, -fill => 'both');
		$ap = $nb->add('about', -label =>'About');
		my $lp = $nb->add('licence', -label => 'License');
		my $t = $lp->Scrolled('ROText', -scrollbars => 'osoe')->pack(-expand =>1, -fill => 'both', @padding);
	} else {
		$ap = $db->Frame->pack(-expand => 1, -fill => 'both');;
	}
	my $lg = $self->ConfigGet('-logo');
	if (defined $lg) {
		$ap->Label(-image => $w->Photo(-file => $lg))->pack;
	}
	my $gf = $ap->Frame->pack(-expand => 1, -fill => 'both');
	my $row = 0;
	my @col0 = ( -column => 0, -sticky => 'e', @padding);
	my @col1 = ( -column => 1, -sticky => 'w', @padding);
	if (exists $inf->{version}) {
		$gf->Label(-text => 'Version:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{version})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{author}) {
		$gf->Label(-text => 'Author:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{author})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{email}) {
		$gf->Label(-text => 'E-mail:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{email})->grid(-row => $row, @col1);
		$row ++;
	}
	if (exists $inf->{http}) {
		$gf->Label(-text => 'Website:')->grid(-row => $row, @col0);
		my $url = $gf->Label(
			-text => $inf->{http},
			-cursor => 'hand2',
		)->grid(-row => $row, @col1);
		my $fg = $url->cget('-foreground');
		$url->bind('<Enter>', sub { $url->configure(-foreground => 'blue') });
		$url->bind('<Leave>', sub { $url->configure(-foreground => $fg) });
		$url->bind('<Button-1>', sub { open_browser $url->cget('-text') });
		$row ++;
	}
	if (exists $inf->{license}) {
		$gf->Label(-text => 'License:')->grid(-row => $row, @col0);
		$gf->Label(-text => $inf->{license})->grid(-row => $row, @col1);
		$row ++;
	}
	$db->Show(-popover => $w);
}

sub CmdHelp {
	my $self = shift;
	my $type = $self->ConfigGet('-helptype');
	my $file = $self->ConfigGet('-helpfile');
	if ($type eq 'pod') {
		my $w = $self->GetAppWindow;
		my $db = $w->AWDialog(
			-buttons => ['Ok'],
			-title => 'Help',
		);
		$db->configure(-command => sub { $db->destroy });
		my $pod = $db->PodText( 
			-file => $file,
			-scrollbars => 'oe',
		)->pack(-expand => 1, -fill => 'both');
		$db->Show(-popover => $w);
	} elsif ($type eq 'html') {
		open_browser $file
	} else {
		warn "Unknown help type: $type"
	}
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath				label					cmd			icon					keyb			config variable
		[	'menu_normal',		'appname::Quit',	"~About", 			'about',		'help-about',		'Shift-F1'	], 
		[	'menu_normal',		'appname::Quit',	"~Help", 			'help',		'help-browser',	'F1',			], 
		[	'menu_separator',	'appname::Quit',	'h1'], 

	)
}


1;
