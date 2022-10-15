package Tk::AppWindow::Ext::MenuBar;

=head1 NAME

Tk::AppWindow::Plugins::MenuBar - a plugin for handling menu's and stuff.

=cut

use strict;
use warnings;
use Tk;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

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

	$self->{MENUPOST} = [];
	$self->Require('Keyboard');
	$self->AddPreConfig(
		-automenu => ['PASSIVE', undef, undef, 1],
		-mainmenuitems => ['PASSIVE', undef, undef, []],
		-menucolspace =>['PASSIVE', undef, undef, 3],
		-menuiconsize =>['PASSIVE', undef, undef, 16],
	);

	$self->AddPostConfig('CreateMenu', $self);
	return $self;
}

=head1 METHODS

=cut

sub AddKeyboardBinding {
	my $self = shift;
	$self->GetAppWindow->CommandExecute('addkeyboardbinding', @_);
}

sub CheckStackForImages {
	my ($self, $stack) = @_;
	my $hasimages = 0;
	my $name = $self->ConfigGet('-appname');
	for (@$stack) {
		my %conv = ( @$_ );
		if (exists $conv{'cascade'}) {
			$self->CheckStackForImages($conv{'-menuitems'})
		}
		if (exists $conv{'-image'}) {
			$hasimages = 1;
		}
		$_->[1] =~ s/appname/$name/;
		
	}
	if ($hasimages) {
		my $size = $self->ConfigGet('-menuiconsize');
		my $empty = $self->CreateEmptyImage($size, $size);
		for (@$stack) {
			my %conv = ( @$_ );
			unless (exists $conv{'-image'}) {
				push @$_, -image => $empty, -compound => 'left';
			}
		}
	}
}

sub ConfDoConfig {
	my ($self, $config, $item) = @_;
	if (defined $config) {
		my $val = '';
		$self->MenuPostAdd(sub { $val = $self->ConfigGet($config) });
		push @$item, -variable => \$val, -command => sub { $self->ConfigPut($config, $val) }
	}
}

sub ConfDoIcon {
	my ($self, $icon, $item) = @_;
	if (defined $icon) {
		my $size = $self->ConfigGet('-menuiconsize');
		my $bmp = $self->GetArt($icon, $size);
		if (defined $bmp) {
			push @$item, -image => $bmp, -compound => 'left'
		}
	}
}

sub ConfDoKeyb {
	my ($self, $command, $keyb, $item) = @_;
	if (defined $keyb) {
		if ((defined $command) and (not $keyb =~ s/^\*//)) {
			my $kb = $self->GetAppWindow->GetExt('Keyboard');
			$kb->AddBinding($command, $keyb);
		}
		push @$item, -accelerator => $keyb;
	}
}

=item B<Configure>;

=cut

my %types = (
	menu => \&ConfMenu,
	menu_check => \&ConfMenuCheck,
	menu_normal => \&ConfMenuNormal,
	menu_radio => \&ConfMenuRadio,
	menu_radio_s => \&ConfMenuRadioGroup,
	menu_separator => \&ConfMenuSeparator,
);

sub Configure {
	my $self = shift;
	my $w = $self->GetAppWindow;
	my $stack = [];
	my @menuitems = @_;
	my $count = 0;
	my $keeploop = 1;
	while ((@menuitems) and $keeploop) {
		my $i = shift @menuitems;
		my @item = @$i;
		my $type = shift @item;
		if (exists $types{$type}) {
			my $c = $types{$type};
			unless (&$c($self, $stack, @item)) {
				push @menuitems, $i
			}
		} else {
			warn "undefined menu type $type"
		}
		$count ++;
		if ($count > 10000) {
			warn "Invalid menupath: " . $item[0];
			$keeploop = 0;
		}
	}
	$self->CheckStackForImages($stack);
	my $menu =$w->Menu(
		-relief => 'flat',
		-menuitems => $stack,
	);
	$w->configure(-menu => $menu);
}

=item B<ConfMenu>($location, $label, $cmd, $icon, $keyb);

=cut

sub ConfMenu {
	my ($self, $stack, $path, $label, $cmd, $icon) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my @item = ('cascade', $label,
		-menuitems => [],
		-postcommand => sub { $self->MenuPost },
	);
	$self->ConfDoIcon($icon,\@item);
	if (defined $cmd) {
		$self->MenuPostAdd($cmd);
	}
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

=item B<ConfMenuNormal>($location, $label, $cmd, $icon, $keyb);

=cut

sub ConfMenuNormal {
	my ($self, $stack, $path, $label, $cmd, $icon, $keyb) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my $w = $self->GetAppWindow;
	my @item = ('command', $label);
	if (defined $cmd) {
		if ($cmd =~ /^<.+>/) {
			$self->ConfVirtEvent($cmd, $keyb) if $cmd =~ /^<<.+>>/;
			push @item, -command => ['eventGenerate', $w, $cmd]
		} else {
			push @item, -command => ['CommandExecute', $w, $cmd];
		}
	}
	$self->ConfDoKeyb($cmd, $keyb,\@item);
	$self->ConfDoIcon($icon,\@item);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

=item B<ConfMenuCheck>($location, $label, $cmd, $icon, $keyb, $config);

=cut

sub ConfMenuCheck {
	my ($self, $stack, $path, $label, $icon, $config, $offvalue, $onvalue) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my $w = $self->GetAppWindow;

	my @item = ('checkbutton', $label);

	push @item, -offvalue => $offvalue if defined $offvalue;
	push @item, -onvalue => $onvalue if defined $onvalue;


	$self->ConfDoIcon($icon,\@item);
	$self->ConfDoConfig($config,\@item);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

sub ConfMenuRadio {
	my ($self, $stack, $path, $label, $icon, $config, $value) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my $w = $self->GetAppWindow;

	my @item = ('radiobutton', $label);

	push @item, -value => $value if defined $value;

	$self->ConfDoIcon($icon,\@item);
	$self->ConfDoConfig($config,\@item);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

=item B<ConfMenuRadio>($location, $label, $cmd, $icon, $keyb, $config);

=cut

sub ConfMenuRadioGroup {
	my ($self, $stack, $path, $label, $values, $icon, $config) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my @item = ();
	my @group = ();
	$self->ConfDoConfig($config,\@item);
	for (@$values) {
		my $value = $_;
		my @i = @item;
		unshift @i, $value;
		unshift @i, 'radiobutton';
		push @i, -value => $value;
		push @group, \@i;
	}
	my @mnu = ('cascade' => $label,
		-menuitems => \@group
	);
	$self->ConfDoIcon($icon,\@mnu);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@mnu
	} else {
		push @$menu, \@mnu
	}
	return 1
}

=item B<ConfMenuSeparator>($location, $label, $cmd, $icon, $keyb, $config);

=cut

sub ConfMenuSeparator {
	my ($self, $stack, $path, $label) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my @item = ('separator', $label);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

sub CreateCompound {
	my ($self, $text, $icon) = @_;
	my $w = $self->GetAppWindow;
	my $comp = $w->Compound;
	my $space = $self->ConfigGet('-menucolspace');
	my $img = undef;
	if (defined $icon) {
		$img = $self->GetArt($icon, $self->ConfigGet('-menuiconsize'));
	}
	if (defined $img) {
		$comp->Image(-image => $img);
		$comp->Space(-width => $space);
		$comp->Text( -text => $text);
	} else {
		$comp->Text( -text => $text);
	}
	return $comp;
}

my $baseline = '                                                                                                                               ';

sub CreateEmptyImage {
	my ($self, $width, $height) = @_;
	my $empty = '/* XPM */
static char * new_xpm[] = {
"' . "$width $height" . ' 3 1",
" 	c None",
".	c #000000",
"+	c #FFFFFF",
';
	my $line = '"' . substr($baseline, 0, $width) . "\"\n";
	for (1 .. $height) {
		$empty = $empty . $line
	}
	return $self->Pixmap(-data => $empty);
}

=item B<CreateMenu>

=cut

sub CreateMenu {
	my $self = shift;
	my $w = $self->GetAppWindow;
	my @u = ();
	if ($w->ConfigGet('-automenu')) {
		my @p = $w->GetExtLoadOrder;
		my @l = ($w);
		for (@p) { push @l, $w->GetExt($_) }
		for (@l) {
			push @u, $_->MenuItems;
		}
	}
	my $m = $w->ConfigGet('-mainmenuitems');
	push @u, @$m;
	$self->Configure(@u);
}

=item B<DecodeMenuPath>($path);

=cut

sub DecodeMenuPath {
	my ($self, $stack, $path) = @_;
	unless (defined $path) {
		my $end = @$stack;
		return ($stack, $end);
	}
	#first weed through the tree of submenu's, if any
	while ($path =~ s/^([^\:]+)\:\://) {
		my $item = $1;
		my $size = @$stack;
		my $count = 0;
		my $found = 0;
		while (($count < $size) and (not $found)) {
			my $label = $stack->[$count]->[1];
			$label =~ s/\~//g;
			if ($label eq $item) {
				$found = 1;
				if ($stack->[$count]->[0] eq 'cascade') {
					$stack = $stack->[$count]->[3];
					if ($path eq '') {
						my $s = @$stack;
						return ($stack, $s)
					}
				} else {
					return ($stack, undef)
				}
			} else {
				$count ++;
			}
		}
	}
	# if the last character in the path is a |, the item should be inserted after the current one.
	my $offset = 0;
	$offset = 1 if $path =~ s/\|$//;

	my $size = @$stack;
	my $count = 0;
	while ($count < $size) {
		my $label = $stack->[$count]->[1];
		$label =~ s/\~//g;
		if ($label eq $path) {
			return ($stack, $count + $offset);
		} else {
			$count ++;
		}
	}
	return ($stack, undef)
}

sub FindMenuEntry {
	my ($self, $path) = @_;
	my $menu = $self->ConfigGet('-menu');
	my $p = $path;
	while ($p =~ s/([^\:]+)\:\://) {
		my $item = $1;
		for (1 .. $menu->index('last')) {
			if ($item eq $menu->entrycget($_, '-label')) {
				if ($menu->type($_) eq 'cascade') {
					$menu = $menu->entrycget($_, '-menu');
				} 
				last
			}
		}
	}
	for (1 .. $menu->index('last')) {
		next if $menu->type($_) eq 'separator';
		if ($p eq $menu->entrycget($_, '-label')) {
			return ($menu, $_);
		}
	}
	warn "Menu entry $path  not found";
}

sub MenuPost {
	my $self = shift;
	my $calls = $self->{MENUPOST};
	my $w = $self->GetAppWindow;
	for (@$calls) {
		if (ref $_) {
			&$_
		} else {
			$w->CommandExecute($_)
		}
	}
}

sub MenuPostAdd {
	my ($self, $cmd) = @_;
	my $calls = $self->{MENUPOST};
	push @$calls, $cmd
}

=item B<Reconfigure>;

=cut

sub ReConfigure {
	my $self = shift;
	$self->{MENUPOST} = [];
# 	$self->DeleteAll;
	$self->CreateMenu;
	return 0;
}


1;
