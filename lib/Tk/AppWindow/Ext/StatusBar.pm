package Tk::AppWindow::Ext::StatusBar;

=head1 NAME

Tk::AppWindow::Ext::FileCommands - a plugin for opening, saving and closing files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Frame;
require Tk::AppWindow::Ext::StatusBar::SImageItem;
require Tk::AppWindow::Ext::StatusBar::SMessageItem;
require Tk::AppWindow::Ext::StatusBar::SProgressItem;
require Tk::AppWindow::Ext::StatusBar::STextItem;

use base qw( Tk::AppWindow::BaseClasses::BarExtension );

my %types = (
	image => {
		class => 'SImageItem',
		pack => [],
	},
	message => {
		class => 'SMessageItem',
		pack => [-expand => 1, -fill => 'both'],
	},
	progress => {
		class => 'SProgressItem',
		pack => [],
	},
	text => {
		class => 'STextItem',
		pack => [],
	},
);

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
	$self->Bar('BOTTOM');
	$self->AddPreConfig(
		-statusitemrelief => ['PASSIVE', undef, undef, 'groove'],
		-statusitemborderwidth => ['PASSIVE', undef, undef, 2],
		-statusitempadding => ['PASSIVE', undef, undef, [-padx =>2, -pady => 2]],
		-statusupdatecycle =>['PASSIVE', undef, undef, 500],
		-statusmsgitemoninit =>['PASSIVE', undef, undef, 1],
	);

	$self->{MI} = undef;
	$self->{ITEMS} = [];

	
	$self->ConfigInit(
		-statusbarvisible	=> ['BarVisible', $self, 1],
	);
	$self->AddPostConfig('InitMsgItem', $self);
	$self->AddPostConfig('Update', $self);
	return $self;
}

=head1 METHODS

=cut


sub Add {
	my $self = shift;
	my $type = shift;
	unless (exists $types{$type}) {
		warn "undefined statusbar type: $type";
		return
	}
	my %params = (@_);
	my $pos = delete $params{'-position'};
	my $class = $types{$type}->{class};
	my $pack = $types{$type}->{pack};
	my $itempadding = $self->ConfigGet('-statusitempadding');
	my $items = $self->{ITEMS};
	if (defined $pos) {
		my $b = $items->[$pos];
		push @$pack, (-before => $b) if defined $b;
	}
	my $i = $self->Subwidget($self->Bar)->$class(%params, 
		-relief => $self->ConfigGet('-statusitemrelief'),
		-borderwidth => $self->ConfigGet('-statusitemborderwidth'),
	)->pack(@$pack, @$itempadding, -side => 'left');
	if (defined $pos) {
		splice @$items, $pos, 0, $i;
	} else {
		push @$items, $i
	}
	return $i
}

sub AddImageItem {
	my $self = shift;
	my %options = (@_);
	my $img = $options{'-valueimages'};
	if (defined $img) {
		for (keys %$img) {
			$img->{$_} = $self->GetArt($img->{$_})
		}
	}
	return $self->Add('image', %options);
}

sub AddMessageItem {
	my $self = shift;
	my $mi = $self->Add('message', @_);
	$self->{MI} = $mi;
	my $bl = $self->GetExt('Balloon');
	$bl->Balloon->configure(-statusbar => $mi) if defined $bl;
	return $mi;
}

sub AddProgressItem {
	my $self = shift;
	return $self->Add('progress', @_);
}

sub AddTextItem {
	my $self = shift;
	return $self->Add('text', @_);
}

sub InitMsgItem {
	my $self = shift;
	$self->AddMessageItem(-position => 0) if ($self->ConfigGet('-statusmsgitemoninit'));
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label			Icon		config variable	keyb
		[	'menu_check',		'View::',		"~Statusbar",	undef,	'-statusbarvisible',	0, 1], 
	)
}

sub Message {
	my $self = shift;
	my $msg = $self->{MI};
	$msg->Message(@_) if defined $msg;
}

sub Update {
	my $self = shift;
	my $items = $self->{ITEMS};
	for (@$items) {
		$_->Update 
	}
	my $time = $self->ConfigGet('-statusupdatecycle');
	$self->after($time, ['Update', $self]);
}

1;
