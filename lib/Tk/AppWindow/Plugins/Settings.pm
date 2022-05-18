package Tk::AppWindow::Plugins::Settings;

=head1 NAME

Tk::AppWindow::Plugins::FileCommands - a plugin for opening, saving and closing files

=cut

use strict;
use warnings;
use Tk;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::AppWindow::AWSettingsDialog;


my %typeclasses = (
	boolean => 'CBooleanItem',
	color => 'CColorItem',
	float => 'CFloatItem',
	'integer' => 'CIntegerItem',
	text => 'CTextItem',
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

=cut

sub CmdSettings {
	my $self = shift;
	my $m = $self->AWSettingsDialog(
		-title => 'Configure settings',
		-plugin => $self,
	);
	$m->Show(-popover => $self);
	$m->destroy;
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
		if (($key eq 'page') or ($key eq 'section')) {
			shift @temp;
			next;
		}
		if ($key eq 'end') {
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
	my @list = $self->PluginList;
	my %hash = ();
	for (@list) {
		$hash{$_->Name} = $_
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

1;
