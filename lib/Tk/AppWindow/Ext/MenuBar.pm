package Tk::AppWindow::Ext::MenuBar;

=head1 NAME

Tk::AppWindow::Ext::MenuBar - handling menu's and stuff.

=cut

use strict;
use warnings;
use Tk;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MenuBar'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a menu to your application.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-automenu>

Default value 1.

Specifies if the menu items of all extensions should be loaded automatically.

=item Switch: B<-mainmenuitems>

Default value [].

Configure your menu here. See the section B<CONFIGURING MENUS> below.

=item Switch: B<-menucolspace>

Default value 3

Space between the colums in a menu item.

=item Switch: B<-menuiconsize>

Default value 16

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->{MENUPOST} = [];
	$self->Require('Keyboard');
	$self->addPreConfig(
		-automenu => ['PASSIVE', undef, undef, 1],
		-mainmenuitems => ['PASSIVE', undef, undef, []],
		-menucolspace =>['PASSIVE', undef, undef, 3],
		-menuiconsize =>['PASSIVE', undef, undef, 16],
	);

	$self->addPostConfig('DoPostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

=cut

sub AddKeyboardBinding {
	my $self = shift;
	$self->GetAppWindow->cmdExecute('addkeyboardbinding', @_);
}

sub CheckStackForImages {
	my ($self, $stack) = @_;
	my $hasimages = 0;
	my $name = $self->configGet('-appname');
	my $art = $self->extGet('Art');
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
		my $size = $self->configGet('-menuiconsize');
		my $empty = $art->CreateEmptyImage($size) if defined $art;
		for (@$stack) {
			my %conv = ( @$_ );
			unless ((exists $conv{'-image'}) and (defined $empty)) {
				push @$_, -image => $empty, -compound => 'left';
			}
		}
	}
}

sub ConfDoConfig {
	my ($self, $config, $item) = @_;
	if (defined $config) {
		my $val = '';
		$self->MenuPostAdd(sub { $val = $self->configGet($config) });
		push @$item, -variable => \$val, -command => sub {	$self->configPut($config, $val) }
	}
}

sub ConfDoIcon {
	my ($self, $icon, $item) = @_;
	if (defined $icon) {
		my $size = $self->configGet('-menuiconsize');
		my $bmp = $self->getArt($icon, $size);
		if (defined $bmp) {
			push @$item, -image => $bmp, -compound => 'left'
		}
	}
}

sub ConfDoKeyb {
	my ($self, $command, $keyb, $item) = @_;
	if (defined $keyb) {
		if ((defined $command) and (not $keyb =~ s/^\*//)) {
			my $kb = $self->GetAppWindow->extGet('Keyboard');
			$kb->AddBinding($command, $keyb);
		}
		push @$item, -accelerator => $keyb;
	}
}

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
	my $menu = $w->cget('-menu');
	unless (defined $menu) {
		$menu = $w->Menu;
		$w->configure(-menu => $menu);
	} else {
		$menu->delete(0, 'end');
	}
	$self->FillMenu($menu, $stack);
# 	my $menu =$w->Menu(
# 		-menuitems => $stack,
# 	);
# 	my $g = $w->geometry;
# 	$w->geometry($g);
}

sub ConfGetCommand {
	my ($self, $cmd) = @_;
	my $w = $self->GetAppWindow;
	if (defined $cmd) {
		if ($cmd =~ /^<.+>/) {
			return -command => ['eventGenerate', $w, $cmd]
		} else {
			return -command => ['cmdExecute', $w, $cmd];
		}
	}
}

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

sub ConfMenuNormal {
	my ($self, $stack, $path, $label, $cmd, $icon, $keyb) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my @item = ('command', $label);
	push @item, $self->ConfGetCommand($cmd) if defined $cmd;
	$self->ConfDoKeyb($cmd, $keyb,\@item);
	$self->ConfDoIcon($icon,\@item);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

sub ConfMenuCheck {
	my ($self, $stack, $path, $label, $icon, $config, $cmd, $offvalue, $onvalue) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my $w = $self->GetAppWindow;

	my @item = ('checkbutton', $label);

	push @item, -offvalue => $offvalue if defined $offvalue;
	push @item, -onvalue => $onvalue if defined $onvalue;
	push @item, $self->ConfGetCommand($cmd) if defined $cmd;


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
	my ($self, $stack, $path, $label, $icon, $config, $cmd, $value) = @_;
	my ($menu, $insertpos) = $self->DecodeMenuPath($stack, $path);
	return 0 unless defined $insertpos;
	my $w = $self->GetAppWindow;

	my @item = ('radiobutton', $label);

	push @item, -value => $value if defined $value;
	push @item, $self->ConfGetCommand($cmd) if defined $cmd;

	$self->ConfDoIcon($icon,\@item);
	$self->ConfDoConfig($config,\@item);
	if ($insertpos <= @$menu) {
		splice @$menu, $insertpos, 0, \@item
	} else {
		push @$menu, \@item
	}
	return 1
}

sub ConfMenuRadioGroup {
	my ($self, $stack, $path, $label, $values, $icon, $config, $cmd) = @_;
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
		push @i, -command => $cmd if defined $cmd;
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
	my $space = $self->configGet('-menucolspace');
	my $img = undef;
	if (defined $icon) {
		$img = $self->getArt($icon, $self->configGet('-menuiconsize'));
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

sub CreateMenu {
	my $self = shift;
	my $w = $self->GetAppWindow;
	my @u = ();
	if ($w->configGet('-automenu')) {
		my @p = $self->extList;
		my @l = ($w);
		for (@p) { push @l, $self->extGet($_) }
		for (@l) {
			push @u, $_->MenuItems;
		}
	}
	my $m = $w->configGet('-mainmenuitems');
	push @u, @$m;
	$self->Configure(@u);
}

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

sub DoPostConfig {
	my $self = shift;
	my $art = $self->extGet('Art');
	if (defined $art) {
		my $size = $self->configGet('-menuiconsize');
		$size = $art->GetAlternateSize($size);
		$self->configPut(-menuiconsize => $size)
	}
	$self->CreateMenu;
}

sub FillMenu {
	my ($self, $menu, $items) = @_;
	while (@$items) {
		my $item = shift @$items;
		my $type = shift @$item;
		my $label = shift @$item;
		my %opt = @$item;
		if ($label =~ /^([^~]*)~([^~]*)/) {
			$opt{'-underline'} = length($1);
			$label = $1 . $2
		}
		$opt{'-label'} = $label;
		if ($type eq 'cascade')  {
			my $menuitems = delete $opt{'-menuitems'};

			my %mnuopt = ();
			for (qw/postcommand selectcolor tearoff tearoffcommand title type/) {
				my $name = "-$_";
				my $val = delete $opt{$name};
				$mnuopt{$name} = $val if defined $val;
			}

			my $submenu = $menu->Menu(%mnuopt);
			$opt{'-menu'} = $submenu;
			$menu->add('cascade', %opt);
			$self->FillMenu($submenu, $menuitems) if defined $menuitems;
		} elsif ($type eq 'separator') {
			$menu->add('separator');
		} else {
			$menu->add($type, %opt);
		}
	}
}

sub FindMenuEntry {
	my ($self, $path) = @_;
	my $menu = $self->configGet('-menu');
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
			$w->cmdExecute($_)
		}
	}
}

sub MenuPostAdd {
	my ($self, $cmd) = @_;
	my $calls = $self->{MENUPOST};
	push @$calls, $cmd
}

sub ReConfigure {
	my $self = shift;
	$self->{MENUPOST} = [];
# 	$self->DeleteAll;
	$self->CreateMenu;
	return 0;
}

=back

=head1 CONFIGURING MENUS

Feeding the B<-menuitems> switch and the B<MenuItems> methods of extensions is
done with a two dimensional list. In Perl:

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MenuBar'],
    -menuitems => [
       [ $type, $path,  
    ],
 );
 $app->MainLoop;

=head1 AUTHOR

=over 4

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
