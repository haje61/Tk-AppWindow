package Tk::AppWindow::Ext::ToolBar;

=head1 NAME

Tk::AppWindow::Ext::ToolBar - add a tool bar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Compound;

use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

=head1 SYNOPSIS

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ToolBar'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=over 4

Add a toolbar to your application.

=back

=head1 B<CONFIG VARIABLES>

=over 4

=item B<-autotool>

=over 4

Default value 1.

Specifies if the toolbar items of all extensions should be loaded automatically.

=back

=item B<-toolbarpanel>

=over 4

Default value 'TOP'. Sets the name of the panel home to B<ToolBar>.

=back

=item B<-toolbarvisible>

=over 4

Default value 1. Show or hide tool bar.

=back

=item B<-tooliconsize>

=over 4

Default value 16

=back

=item B<-toolitems>

=over 4

Default value [].

Configure your tool bar here. Example:

 [    #type             #label   #command     #icon             #help
    [	'tool_button',   'New',   'file_new',   'document-new',   'Create a new document'],
    [	'tool_separator' ],
 ]

=back

=item B<-tooltextposition>

=over 4

Default value I<right>. Can be I<top>, I<left>, I<bottom>, I<right> or I<none>.

=back

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('Art');
	$self->ConfigInit(
		-toolbarpanel => ['Panel', $self, 'TOP'],
		-toolbarvisible => ['PanelVisible', $self, 1],
	);

	$self->AddPreConfig(
		-autotool => ['PASSIVE', undef, undef, 1],
		-tooliconsize => ['PASSIVE', 'ToolIconSize', 'toolIconSize', 16],
		-toolitems => ['PASSIVE', undef, undef, []],
		-tooltextposition => ['PASSIVE', undef, undef, 'right'],
	);
	$self->{TYPESTABLE} = {};
	$self->{ITEMLIST} = [];
	$self->ConfigureTypes(
		tool_button			=> ['ConfToolButton', $self],
		tool_separator		=> ['ConfToolSeparator', $self],
	);

	$self->AddPostConfig('DoPostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<AddItem>I<$item, ?$position?);

=over 4

Adds an item to the toolbar. The item must be a valid tk widget.
Your addition will be lost after a call to B<ReConfigure>.

=back

=cut

sub AddItem {
	my ($self, $item, $position) = @_;
	my $list = $self->{ITEMLIST};
	my $before;
	if (defined $position) {
		$position = @$list if $position > @$list;
		$before = $list->[$position];
	}
	my $bar = $self->Subwidget($self->Panel);
	my @pack = (-side => 'left', -padx => 2, -in => $bar, -fill => 'y');
	if (defined $before) {
		$item->pack(@pack, -before => $before);
		splice @$list, $position, 0, $item;
	} else {
		$item->pack(@pack);
		push @$list, $item;
	}
}

=item B<AddSeparator>I<?$position?);

=over 4

Adds a separator to the toolbar.
Your addition will be lost after a call to B<ReConfigure>.

=back

=cut

sub AddSeparator {
	my $self = shift;
	$self->AddItem($self->Subwidget($self->Panel)->Label(-text => '|'), @_);
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

=item B<ConfigureTypes>I<($type => $call, ...);

=over 4

Call this method before MainLoop runs.
Configure additional types for your toolbar.
Already defined types are i<tool_button> and I<-tool_separator>.
I<$call> can be any valid Tk callback. Just make sure the callback
returns a valid Tk widget.

=back

=cut

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
	my $tb = $self->Subwidget($self->Panel);

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
			push @balloon, -balloonmsg => $label;
		}
		my $art = $self->GetExt('Art');
		my $compound = $art->CreateCompound(
			-text => $label,
			-image => $bmp,
			-textside => $textpos,
		);
		$but = $tb->Button(-image => $compound);
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
	my $w = $self->GetAppWindow;
	if ($self->ConfigGet('-autotool')) {
		my @p = $self->ExtensionList;
		my @l = ($w);
		for (@p) { push @l, $w->GetExt($_) }
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

sub DoPostConfig {
	my $self = shift;

	#fixing possible mismatch of iconsize at launch
	my $art = $self->GetExt('Art');
	my $size = $self->ConfigGet('-tooliconsize');
	$size = $art->GetAlternateSize($size);
	$self->ConfigPut(-tooliconsize => $size);

	$self->CreateItems;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label					Icon		config variable	   off  on
		[	'menu_check',		'View::',		"Show ~toolbar",	undef,	'-toolbarvisible',	0,   1], 
	)
}

sub ReConfigure {
	my $self = shift;
	$self->DeleteAll;
	$self->CreateItems;
}

=item B<RemoveItem>I<$position);

=over 4

Removes the item at $position from the tool bar.
The item will re-appear after a call to B<ReConfigure> if the item is included in the B<-toolitems> option.
Returns the removed item.

=back

=cut

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
