package Tk::AppWindow;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use Tk::GtkSettings qw(gtkKey initDefaults export2xrdb groupOption);
initDefaults;
my $iconlib = gtkKey('gtk-icon-theme-name');
# $iconlib = ucfirst($iconlib);
groupOption('main', 'iconTheme', $iconlib) if defined $iconlib;
export2xrdb;
# applyGtkSettings;

use base qw(Tk::Derived Tk::MainWindow);
Construct Tk::Widget 'AppWindow';

use File::Basename;
use Module::Load::Conditional('check_install', 'can_load');
require Tk::AppWindow::BaseClasses::Callback;
require Tk::AppWindow::AWMessage;
require Tk::PNG;
# use Tk::Xrm;

sub Populate {
	my ($self,$args) = @_;
	
	my $commands = delete $args->{'-commands'};
	$commands = [] unless defined $commands;

	my $plugins = delete $args->{'-plugins'};
	$plugins = [] unless defined $plugins;
	
	my $preconfig = delete $args->{'-preconfig'};
	$preconfig = [] unless defined $preconfig;
	
	my $appname = delete $args->{'-appname'};
	$appname = ucfirst(basename($0, '.pl', '.PL')) unless defined $appname;
	$args->{'-title'} = $appname;
	
	$self->SUPER::Populate($args);

	$self->{APPNAME} = $appname;
	$self->{ARGS} = $args;
	$self->{CMNDTABLE} = {};
	$self->{CONFIGTABLE} = {};
	$self->{PLUGINS} = {};
	$self->{PLUGLOADORDER} = [];
	$self->{WORKSPACE} = $self;
	$self->{VERBOSE} = 0;

	$self->CommandsConfig(
		poptest => ['PopTest', $self], #usefull for testing only
		quit => ['CmdQuit', $self],
		@$commands
	);
	$self->ConfigInit(
		-appname => ['AppName', $self, $appname],
		-verbose => ['Verbose', $self, 0],
	);
	
	$self->{POSTCONFIG} = [];
	$self->{PRECONFIG} = $preconfig;
	for (@$plugins) {
		$self->LoadPlugin($_, $args);
	}
	
	my $setplug = $self->GetPlugin('Settings');
	if (defined $setplug) {
		my @useroptions = $setplug->LoadSettings;
		my $tab = $self->{CONFIGTABLE};
		while (@useroptions) {
			my $option = shift @useroptions;
			my $value = shift @useroptions;
			if (exists $tab->{$option}) {
				$self->ConfigPut($option, $value)
			} else {
				$args->{$option} = $value;
			}
		}
	}
	my $pre = $self->{PRECONFIG};
	$self->ConfigSpecs(
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#FF0000'],
		-logo => ['PASSIVE', undef, undef, Tk::findINC('Tk/AppWindow/aw_logo.png')],
		@$pre,
		DEFAULT => ['SELF'],
	);

	$self->protocol('WM_DELETE_WINDOW', ['CmdQuit', $self]);
	delete $self->{ARGS};
	$self->after(1, ['PostConfig', $self]);
}

sub AddPostConfig {
	my $self = shift;
	my $pc = $self->{POSTCONFIG};
	my $call = $self->CreateCallback(@_);
	push @$pc, $call
}

sub AddPreConfig {
	my $self = shift;
	my $p = $self->{PRECONFIG};
	push @$p, @_
}

sub AppName {
	my $self = shift;
	if (@_) { $self->{APPNAME} = shift }
	return $self->{APPNAME}
}

=item B<CanQuit>

returns 1. It is called when Wx::Perl::FrameWorks is asking all plugins if it can quit. You can 
overwrite it when you inherit Wx::Perl::FrameWorks.

=cut

sub CanQuit {
	return 1
}

=item B<CmdQuit>

The method that gets called when you execute the 'quit' command.
It queries all plugins for permission and exits.

=cut

sub CmdQuit {
	my $self = shift;
	my $quit = 1;
	my $plgs = $self->{PLUGINS};
	for (keys %$plgs) {
		$quit = 0 unless $plgs->{$_}->CanQuit;
	}
	$quit = 0 unless $self->CanQuit;
	if ($quit) {
		$self->destroy;
	} 
}

=item B<CommandsConfig>(

    command1 => ['SomeMethod', $obj, @options],
    command2 => [sub { do whatever }, @options],
 );

CommandsConfig takes a paired list of commandnames and callback descriptions.
It registers them to the commands table. After that B<CommandExecute> can 
be called on them.

=cut

sub CommandsConfig {
	my $self = shift;
	while (@_) {
		my $key = shift;
		my $callback = shift;
		$self->CommandRegister($key, $callback);
	}
}

=item B<CommandExecute>('command_name', @options);

Looks for the callback assigned to command_name and executes it.
It first passes the options you specify here. Then it passes the
options you specified in B<CommandsConfig>. My advise is to make
a clear choice. Either specify all options here and nothing in
B<CommandsConfig>. Or have all the options in B<CommandsConfig> and
specify nothing here. This method is called by menu items, toolbar items
and whatever you specify.

=cut

sub CommandExecute {
	my $self = shift;
	my $key = shift;
	my $cmd = $self->{CMNDTABLE}->{$key};
	if (defined $cmd) {
		return $cmd->Execute(@_);
	} else {
		warn "Command $key is not defined"
	}
}

=item B<CommandExists>('command_name')

Checks if command_name can be used as a command. Returns 1 or 0.

=cut

sub CommandExists {
	my ($self, $key) = @_;
	unless (defined $key) { return 0 }
	return exists $self->{CMNDTABLE}->{$key};
}

=item B<CommandRegister>('command_name', $reftocallback);

Called by CommandsConfig. This would be an alternative
way to define a command. The reference can be to any
object, as long as it has a B<Execute> method.

=cut

sub CommandRegister {
	my ($self, $key, $callback) = @_;
	my $tbl = $self->{CMNDTABLE};
	unless (exists $tbl->{$key}) {
		$tbl->{$key} = $self->CreateCallback(@$callback);
	} else {
		warn "Command $key already exists"
	}
}

sub ConfigGet {
	my ($self, $option) = @_;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		return $call->Execute;
	} else {
		return $self->cget($option);
	}
}

sub ConfigInit {
	my $self = shift;
	my $args = $self->{ARGS};
	my $table = $self->{CONFIGTABLE};
	while (@_) {
		my $option = shift;
		my $i = shift;
		my ($call, $owner, $default) = @$i;
		my $value = delete $args->{$option};
		unless (defined $value) { $value = $default };
		unless (exists $table->{$option}) {
			$table->{$option} = $self->CreateCallback($call, $owner);
			$self->ConfigPut($option, $value);
		} else {
			warn "Config option $option already defined\n";
		}
	}
}

sub ConfigPut {
	my ($self, $option, $value) = @_;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		$call->Execute($value);
	} else {
		$self->configure($option, $value);
	}
}

=item B<CreateCallback>('MethodName', $owner, @options);

=item B<CreateCallback>(sub { do whatever }, @options);

Creates and returns a Wx::Perl::Baseclasses::Callback object. 
A convenience method that saves you some typing.

=cut

sub CreateCallback {
	my $self = shift;
	return Tk::AppWindow::BaseClasses::Callback->new(@_);
}

=item B<CreateOptionsFileName>

Composes the full file name of the user options file.

=cut

sub CreateOptionsFileName {
	my $self = shift;
	my $dir = $self->ConfigGet('-settingsfolder');
	my $file = $self->ConfigGet('-useroptionsfile');
	return "$dir/$file";
}

=item B<GetArt>($icon);

=cut

sub GetArt {
	my ($self, $icon, $size) = @_;
	my $art = $self->GetPlugin('Art');
	if (defined $art) {
		return $art->GetIcon($icon, $size);
	}
	return undef
}

=item B<GetPlugin>('PluginName')

Returns the position of 'PluginName' in the plugin stack.
returns undef if the plugin is not loaded.

=cut

sub GetPlugin {
	my ($self, $name) = @_;
	my $plgs = $self->{PLUGINS};
	if (exists $plgs->{$name}) {
		return $plgs->{$name}
	}
	return undef
}

sub GetPlugLoadOrder {
	my $self = shift;
	my $o = $self->{PLUGLOADORDER};
	return @$o;
}

=item B<LoadPlugin>('PluginName');

Loads and initializes the plugin. It uses B<Module::Load::Conditional> to do so.
If it fails it will give a warning. No crashes here. Also no error messages.

=cut

sub LoadPlugin {
	my ($self, $name, $args) = @_;
	my $plgs = $self->{PLUGINS};
	my $plug = undef;
	unless (exists $plgs->{$name}) { #unless already loaded
		my $module = "Tk::AppWindow::Plugins::$name";
		my $inst = check_install(module => $module);
		if (defined $inst) {
			if (can_load(modules => {$module => $inst->{'version'}})){
				$plug = $module->new($self, $args);
			}
		}
		if (defined($plug)) {
			print "Plugin $name loaded\n" if $self->Verbose;
			$plgs->{$name} = $plug;
			$plug->CleanUp;
			my $o = $self->{PLUGLOADORDER};
			push @$o, $name;
		} else {
			warn "unable to load plugin $name\n";
		}
	}
}

=item B<LoadUserOptions>

Loads the user options file in the settings folder if it exists.Called by the constructor.

=cut

sub LoadUserOptions {
	my $self = shift;
	my $file = $self->CreateOptionsFileName;
	my %useroptions = ();
	unless (-e $file) { return \%useroptions }
	if (open(OFILE, "<", $file)) {
		while (<OFILE>) {
			my $line = $_;
			chomp $line;
			if ($line =~ s/^([^=]+)=//) {
				my $option = $1;
				$useroptions{$option} = $line;
			} else {
				warn "unrecognized format: $line"
			}
		}
		close OFILE;
	} else {
		warn "cannot open file $file";
	}
# 	if ($debug) { print "user defined options", Dumper(\%useroptions) }
	return \%useroptions;
}

=item B<MenuItems>

Returns a list of two items used by the B<MenuBar> plugin. The first defines the file menu.
The second is the menu option Quit in this menu. Overwrite this method to make it return
a different list. See also B<Wx::Perl::FrameWorks::Plugins::MenuBar>

=cut

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd			icon							keyb			config variable
		[	'menu', 				undef,			"~appname", 		], 
		[	'menu_normal',		'appname::',		"~Quit",					'quit',		'application-exit',		'Control-q',	], 
	)
}

=item B<PluginList>

Returns a list of all loaded plugins

=cut

sub PluginList {
	my $self = shift;
	my $pl = $self->{PLUGINS};
	my @plugs = ();
	for (keys %$pl) { push @plugs, $pl->{$_} }
	return @plugs;
}

sub PopMessage {
	my ($self, $text, $icon, $size) = @_;
	$icon = 'dialog-information' unless defined $icon;
	$size = 32 unless defined $size;
	my $m = $self->AWMessage(
		-text => $text,
		-image => $self->GetArt($icon, $size),
	);
	$m->Show(-popover => $self);
	$m->destroy;
}

sub PopTest {
	my $self = shift;
	$self->PopMessage("you did something");
}

sub PostConfig {
	my $self = shift;
   my $lgf = $self->cget('-logo');
   if ((defined $lgf) and (-e $lgf)) {
      my $logo = $self->Photo(-file => $lgf, -format => 'PNG');
      $self->iconphoto($logo);
   }
	my $pc = $self->{POSTCONFIG};
	for (@$pc) { $_->Execute }
}

=item B<ToolItems>

Returns an empty list. It is called by the B<ToolBar> plugin. Overwrite it
if you like.

=cut

sub ToolItems {
	my $self = shift;
	return (
	)
}

sub Verbose {
	my $self = shift;
	$self->{VERBOSE} = shift if @_;
	return $self->{VERBOSE}
}

sub WorkSpace {
	my $self = shift;
	$self->{WORKSPACE} = shift if @_;
	return $self->{WORKSPACE}
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hansjeuken@xs4all.nl)

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
__END__
