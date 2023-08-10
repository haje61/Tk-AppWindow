package Tk::AppWindow::Ext::Settings;

=head1 NAME

Tk::AppWindow::Ext::Settings - allow your user to configure settings

=cut

use strict;
use warnings;
use Tk;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

require Tk::YADialog;
require Tk::QuickForm;


=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Settings'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Add a settings feature to your application and allow the end user to configure the application.

Creates a menu item in the main menu.

Loads settings file at startup.

=head1 CONFIG VARIABLES

=over 4

=item B<-settingsfile>

Name of the settings file. Default is I<settingsrc>.

=item B<-useroptions>

Name of the settings file. Default is I<settingsrc>. A typical setup might look
like this:

 -useroptions => [
    '*page' => 'Editing',
    '*section' => 'User interface',
    -contentforeground => ['color', 'Foreground'],
    -contentbackground => ['color', 'Background'],
    -contentfont => ['font', 'Font'],
    '*end',
    '*section' => 'Editor settings',
    -contenttabs => ['text', 'Tab size'],
    -contentwrap => ['radio', 'Wrap', [qw[none char word]]],
    '*end',
    '*page' => 'Icons',
    -icontheme => ['list', 'Icon theme', 'available_icon_themes'],
    -iconsize => ['list', 'Icon size', 'available_icon_sizes'],
    '*page' => 'Bars',
    '*section' => 'Menubar',
    -menuiconsize => ['list', 'Icon size', 'available_icon_sizes'],
    '*end',
    '*section' => 'Toolbar',
    -toolbarvisible => ['boolean', 'Visible at launch'],
    -tooliconsize => ['list', 'Icon size', 'available_icon_sizes'],
    -tooltextposition => ['radio', 'Text position', [qw[none left right top bottom]]],
    '*end',
    '*section' => 'Statusbar',
    -statusbarvisible => ['boolean', 'Visible at launch'],
    '*end',
 ],

It uses L<Tk::TabbedForm> in the popup. See there for details of this option.

=back

=head1 COMMANDS

=over 4

=item B<settings>

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $args = $self->GetArgsRef;

	$self->Require( 'ConfigFolder');
	$self->{SETTINGSFILE} = undef;
	$self->{USEROPTIONS} = undef;

	
	$self->ConfigInit(
		-settingsfile => ['SettingsFile', $self, 'settingsrc'],
		-useroptions => ['UserOptions', $self, []],
	);

	$self->CommandsConfig(
		settings => [\&CmdSettings, $self],
	);

	return $self;
}

=head1 METHODS

=over 4

=cut

sub CmdSettings {
	my $self = shift;
	my $m = $self->GetAppWindow->YADialog(
		-buttons => ['Close'],
		-title => 'Configure settings',
	);
	
	my $f;
	my $b = $m->Subwidget('buttonframe')->Button(
		-text => 'Apply',
		-command => sub {
			my %options = $f->get;
			my @opts = sort keys %options;
			my @save = ();
			for (@opts) {
				my $val = $options{$_};
				if ($val ne '') {
					$self->ConfigPut($_, $val);
					push @save, $_;
				}
			}
			$self->ReConfigureAll;
			$self->SaveSettings(@save);
		}
	);
	$f = $m->QuickForm(
		-acceptempty => 1,
# 		-listcall => ['CommandExecute', $self],
		-structure => $self->ConfigGet('-useroptions'),
		-postvalidatecall => sub {
			my $flag = shift;
			if ($flag) {
				$b->configure('-state', 'normal')
			} else {
				$b->configure('-state', 'disabled')
			}
		},
	)->pack(-expand => 1, -fill => 'both');
	$f->createForm;
	$f->put($self->GetUserOptions);
	
	$m->ButtonPack($b);
	$m->Show(-popover => $self->GetAppWindow);
	$m->destroy;
}

sub GetUserOptions {
	my $self = shift;
	my $uo = $self->ConfigGet('-useroptions');
	my @options = @$uo;
	my %usopt = ();
	while (@options) {
		my $key = shift @options;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @options;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		shift @options;
		$usopt{$key} = $self->ConfigGet($key);
	}
	return %usopt
}

sub LoadSettings {
	my $self = shift;
	my $file = $self->ConfigGet('-configfolder') . "/" . $self->ConfigGet('-settingsfile');
	return () unless -e $file;
	my $uo = $self->ConfigGet('-useroptions');
	my %useroptions = ();
	my @temp = (@$uo);
	while (@temp) {
		my $key = shift @temp;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @temp;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		shift @temp;
		$useroptions{$key} = 1;
	}
	my @output = ();
	if (open(OFILE, "<", $file)) {
		while (<OFILE>) {
			my $line = $_;
			chomp $line;
			if ($line =~ s/^([^=]+)=//) {
				my $option = $1;
				if (exists $useroptions{$option}) {
					push @output, $option, $line
				} else {
					warn "Ignoring invalid option: $option"
				}
			}
		}
		close OFILE;
	}
	return @output;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath					label				cmd			icon					keyb
		[	'menu_normal',		'appname::Quit',		'~Settings',	'settings',	'configure',		'F9',	], 
		[	'menu_separator',	'appname::Quit',		'h2'], 
	)
}

sub ReConfigureAll {
	my $self = shift;
	my @list = $self->ExtensionList;
	my %hash = ();
	for (@list) {
		$hash{$_} = $self->GetExt($_);
	}
	my $kb = delete $hash{'Keyboard'};
	$kb->ReConfigure if defined $kb;
	for (keys %hash) {
		$hash{$_}->ReConfigure;
	}
}

sub SaveSettings {
	my $self = shift;
	my $file = $self->ConfigGet('-configfolder') . "/" . $self->ConfigGet('-settingsfile');
	if (open(OFILE, ">", $file)) {
		for (@_) {
			my $option = $_;
			my $value = $self->ConfigGet($_);
			print "saving $option with value $value\n";
			print OFILE $option, '=', $value, "\n";
		}
		close OFILE;
		return 1
	}
	return 0
}

sub SettingsFile {
	my $self = shift;
	if (@_) { $self->{SETTINGSFILE} = shift }
	return $self->{SETTINGSFILE}
}

sub UserOptions {
	my $self = shift;
	if (@_) { $self->{USEROPTIONS} = shift }
	return $self->{USEROPTIONS}
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
