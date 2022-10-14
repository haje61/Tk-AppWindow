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

require Tk::YADialog;
require Tk::TabbedForm;


=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION

=cut

=head1 CONFIG VARIABLES

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
	my $m = $self->GetAppWindow->YADialog(
		-buttons => ['Close'],
		-title => 'Configure settings',
	);
	
	my $f;
	my $b = $m->Subwidget('buttonframe')->Button(
		-text => 'Apply',
		-command => sub {
			my %options = $f->Get;
			my @opts = sort keys %options;
			for (@opts) {
				my $val = $options{$_};
				$self->ConfigPut($_, $val) if $val ne '';
			}
			$self->ReConfigureAll;
			$self->SaveSettings(@opts);
		}
	);
	$f = $m->TabbedForm(
		-listcall => ['CommandExecute', $self],
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
	$f->CreateForm;
	$f->Put($self->GetUserOptions);
	
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
