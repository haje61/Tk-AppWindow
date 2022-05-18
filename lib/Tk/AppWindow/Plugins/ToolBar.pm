package Tk::AppWindow::Plugins::ToolBar;

=head1 NAME

Tk::AppWindow::Plugins::ToolBar - a toolbar plugin

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Compound;

use base qw( Tk::AppWindow::BaseClasses::BarPlugin );

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
		-autotool => ['PASSIVE', undef, undef, 1],
		-tooliconsize => ['PASSIVE', 'ToolIconSize', 'toolIconSize', 16],
		-toolitems => ['PASSIVE', undef, undef, []],
		-tooltextposition => ['PASSIVE', undef, undef, 'right'],
		-toolbarvisible => ['PASSIVE', undef, undef, 1],
	);
	$self->{TYPESTABLE} = {};
	$self->{ITEMLIST} = [];
	$self->ConfigureTypes(
		tool_button			=> ['ConfToolButton', $self],
		tool_separator		=> ['ConfToolSeparator', $self],
	);

	$self->Bar($self->Subwidget('TOP'));
	$self->Position('TOP');
	$self->ConfigInit(
		-toolbarvisible	=> ['BarVisible', $self, 1],
	);

	$self->AddPostConfig('CreateItems', $self);
	return $self;
}

=head1 METHODS

=cut

sub AddItem {
	my ($self, $item, $position) = @_;
	my $list = $self->{ITEMLIST};
	my $before;
	if (defined $position) {
		$position = @$list if $position > @$list;
		$before = $list->[$position];
	}
	if (defined $before) {
		$item->pack(-side => 'left', -padx => 2, -in => $self->Bar, -fill => 'y');
		splice @$list, $position, 0, $item;
	} else {
		$item->pack(-side => 'left', -padx => 2, -in => $self->Bar, -fill => 'y');
		push @$list, $item;
	}
}

sub AddSeparator {
	my $self = shift;
	$self->AddItem($self->Bar->Label(-text => '|'), @_);
}

sub ClearTools {
	my $self = shift;
	my $list = $self->{ITEMLIST};
	for (@$list) {
		$_->packForget;
	}
	my @removed = @$list;
	@$list = ();
	return @removed;
}

sub Configure {
	my $self = shift;
	my $uitypes = $self->{TYPESTABLE};
	while (@_) {
		my $i = shift;
		my @item = @$i;
		my $type = shift @item;
		if (defined $type) {
			if (my $p = $uitypes->{$type}) {
				$p->Execute(@item);
			} else {
				warn "invalid type: $type"
			}
		} else {
			warn "undefined type"
		}
	}
}

sub ConfigureTypes {
	my $self = shift;
	my $tab = $self->{TYPESTABLE};
	while (@_) {
		my $type = shift;
		my $call = shift;
		$tab->{$type} = $self->CreateCallback(@$call);
	}
}

sub ConfToolButton {
	my ($self, $label, $cmd, $icon, $help) = @_;
	my $tb = $self->Bar;

	my $bmp;
	if (defined $icon) {
		$bmp = $self->GetArt($icon, $self->ConfigGet('-tooliconsize'));
	}

	my @balloon = ();
	push @balloon, -statusmsg => $help if defined $help;
	my $textpos = $self->ConfigGet('-tooltextposition');
	my $but;

	if (defined $bmp) {
		if ($textpos eq 'none') {
			$but = $tb->Button(-image => $bmp);
			push @balloon, -balloonmsg => $label;
		} else {
			my $compound = $tb->Compound;
			if ($textpos eq 'left') {
				$compound->Text(-text => $label, -anchor => 'c');
				$compound->Space(-width => 2);
				$compound->Image(-image => $bmp);
			} elsif ($textpos eq 'right') {
				$compound->Image(-image => $bmp);
				$compound->Space(-width => 2);
				$compound->Text(-text => $label, -anchor => 'c');
			} elsif ($textpos eq 'top') {
				$compound->Text(-text => $label, -anchor => 'c');
				$compound->Line;
				$compound->Image(-image => $bmp);
			} elsif ($textpos eq 'bottom') {
				$compound->Image(-image => $bmp);
				$compound->Line;
				$compound->Text(-text => $label, -anchor => 'c');
			} else {
				$compound->Text(-text => $label);
				$compound->Space(-width => 2);
				$compound->Image(-image => $bmp);
				warn "illegal value for -tooltextposition. should be: none, left, right, top or bottom"
			}
			$but = $tb->Button(-image => $compound);
		}
	} else {
		$but = $tb->Button(-text => 'Label');
	}
	$self->BalloonAttach($but, @balloon) if @balloon;
	my $call;
	if ($cmd =~ /^<.+>/) { #matching an event
		$call = ['eventGenerate', $self, $cmd] 
	} else {
		$call = ['CommandExecute', $self, $cmd]
	}
	$but->configure(
		-command => $call,
		-relief => 'flat'
	);
	$self->AddItem($but);
}

sub ConfToolSeparator {
	my $self = shift;
	$self->AddSeparator;
}

sub CreateItems {
	my $self = shift;
	my @u = ();
	if ($self->ConfigGet('-autotool')) {
		my @l = $self->PluginList;
		for (@l) {
			push @u, $_->ToolItems;
		}
	}
	my $m = $self->ConfigGet('-toolitems');
	push @u, @$m;
	$self->Configure(@u);
}

sub DeleteAll {
	my $self = shift;
	my @removed = $self->ClearTools;
	for (@removed) { $_->destroy };
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label			Icon		config variable	keyb
		[	'menu_check',		'View::',		"~Toolbar",	undef,	'-toolbarvisible',	0, 1], 
	)
}

sub ReConfigure {
	my $self = shift;
	$self->DeleteAll;
	$self->CreateItems;
}

sub RemoveItem {
	my ($self, $position) = @_;
	my $list = $self->{ITEMLIST};
	if (defined $position) {
		$position = @$list if $position > @$list;
		my $item = $list->[$position];
		$item->packForget if defined $item;
		return $item;
	}
}

1;
