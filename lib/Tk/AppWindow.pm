package Tk::AppWindow;

=head1 NAME

Tk::AppWindow - an application framework based on Tk

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";

use Tk::GtkSettings qw(gtkKey initDefaults export2xrdb groupOption);
initDefaults;
my $iconlib = gtkKey('gtk-icon-theme-name');
groupOption('main', 'iconTheme', $iconlib) if defined $iconlib;
export2xrdb;

use base qw(Tk::Derived Tk::MainWindow);
Construct Tk::Widget 'AppWindow';

use Config;
use File::Basename;
require Tk::AppWindow::BaseClasses::Callback;
require Tk::YAMessage;
require Tk::PNG;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

B<Tk::AppWindow> is a modular application framework written in perl/Tk.
It is a base application that can be extended.
The aim is maximum user configurability and ease of application building.

To get started read L<Tk::AppWindow::OverView>.

This document is a reference manual.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-appname>

Set the name of your application.

If this option is not specified, the name of your application
will be set to the filename of your executable with the first
character in upper case.

=item Switch: B<-commands>

Defines commands to be used in your application. It takes a paired list of
command names and callbacks as parameter.

 my $app = $k::AppWindw->new(
    -commands => [
       do_something1 => ['method', $obj],
       do_something2 => sub { return 1 },
    ],
 );

Only available at create time.

=item Name  : B<errorColor>

=item Class : B<ErrorColor>

=item Switch: B<-errorcolor>

Default value '#FF0000' (red).

=item Switch: B<-extensions>

Specifies the list of extensions to be loaded.

 my $app = $k::AppWindw->new(
    -extensions => [ 
       qw/Art Balloon ConfigFolder
       Help Keyboard MDI MenuBar
       Navigator Panels Plugins
       SDI Settings StatusBar ToolBar/
    ],
 );

The following order matters for the buildup of menus and bars.
Only available at create time.

=item Switch: B<-logo>

Specifies the image file to be used as logo for your application.
Default value is Tk::findINC('Tk/AppWindow/aw_logo.png').

=item Switch: B<-savegeometry>

Default value is 1

If set it will save the applications geometry on exit.
When reloaded the previously saved geometry is restored.
In experimental stage

=back

=item Switch: B<-verbose>

Default value is 0.
Set or get verbosity.
Does not do anything at this moment. Meant for logging.

=back

=head1 B<COMMANDS>

=over 4

=item B<quit>

Calls the CmdQuit method. See there.

=back

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $commands = delete $args->{'-commands'};
	$commands = [] unless defined $commands;

	my $extensions = delete $args->{'-extensions'};
	$extensions = [] unless defined $extensions;
	
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
	$self->{EXTENSIONS} = {};
	$self->{EXTLOADORDER} = [];
	$self->{OSNAME} = $Config{'osname'};
	$self->{WORKSPACE} = $self;
	$self->{VERBOSE} = 0;

	$self->cmdConfig(
		poptest => ['popTest', $self], #usefull for testing only
		quit => ['CmdQuit', $self],
		@$commands
	);
	$self->configInit(
		-appname => ['appName', $self, $appname],
		-verbose => ['Verbose', $self, 0],
	);
	
	$self->{POSTCONFIG} = [];
	$self->{PRECONFIG} = $preconfig;
	for (@$extensions) {
		$self->extLoad($_, $args);
	}

	my $setplug = $self->extGet('Settings');
	if (defined $setplug) {
		my @useroptions = $setplug->LoadSettings;
		my $tab = $self->{CONFIGTABLE};
		while (@useroptions) {
			my $option = shift @useroptions;
			my $value = shift @useroptions;
			if (exists $tab->{$option}) {
				$self->configPut($option, $value)
			} else {
				$args->{$option} = $value;
			}
		}
	}
	my $pre = $self->{PRECONFIG};
	$self->ConfigSpecs(
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#FF0000'],
		-initpaneldelay => ['PASSIVE', undef, undef, 500],
		-logcall => ['CALLBACK', undef, undef, sub { print STERR shift }], 
		-logerrorcall => ['CALLBACK', undef, undef, sub { print STERR shift }], 
		-logo => ['PASSIVE', undef, undef, Tk::findINC('Tk/AppWindow/aw_logo.png')],
		-savegeometry => ['PASSIVE', undef, undef, 1],
		@$pre,
		DEFAULT => ['SELF'],
	);

	$self->protocol('WM_DELETE_WINDOW', ['CmdQuit', $self]);
	delete $self->{ARGS};
	$self->after(1, ['PostConfig', $self]);
}

=head1 B<METHODS>

=over 4

=item B<addPostConfig>I<('Method', $obj, @options)>

Only to be called by extensions at create time.
Specifies a callback te be executed after main loop starts.

Callbacks are executed in the order they are added.

=cut

sub addPostConfig {
	my $self = shift;
	my $pc = $self->{POSTCONFIG};
	my $call = $self->CreateCallback(@_);
	push @$pc, $call
}

=item B<addPreConfig>I<(@configs)>

Only to be called by extensions at create time.
Specifies configs to the ConfigSpec method executed in Populate.

=cut

sub addPreConfig {
	my $self = shift;
	my $p = $self->{PRECONFIG};
	push @$p, @_
}

=item B<appName>I<($name)>

Sets and returns the application name.
Same as $app->configPut(-name => $name), or $app->configGet($name).

=cut

sub appName {
	my $self = shift;
	if (@_) { $self->{APPNAME} = shift }
	return $self->{APPNAME}
}

=item B<CanQuit>

Returns 1. It is called when Tk::AppWindow tests all extensions if they can quit. You can 
overwrite it when you inherit Tk::AppWindow.

=cut

sub CanQuit {
	my $self = shift;
	return 1
}

sub CmdQuit {
	my $self = shift;
	my $quit = 1;
	my $plgs = $self->{EXTENSIONS};
	for (keys %$plgs) {
		$quit = 0 unless $plgs->{$_}->CanQuit;
	}
	$quit = 0 unless $self->CanQuit;
	if ($quit) {
		if ($self->extExists('ConfigFolder') and $self->configGet('-savegeometry')) {
			my $geometry = $self->geometry;
			my $file = $self->configGet('-configfolder') . '/geometry';
			if (open(OFILE, ">", $file)) {
				print OFILE $geometry . "\n";
				close OFILE
			}
		}
		$self->destroy;
	} 
}

=item B<cmdConfig>I<(@commands)>

 $app->cmdConfig(
    command1 => ['SomeMethod', $obj, @options],
    command2 => [sub { do whatever }, @options],
 );

cmdConfig takes a paired list of commandnames and callback descriptions.
It registers them to the commands table. After that B<cmdExecute> can 
be called on them.

=cut

sub cmdConfig {
	my $self = shift;
	my $tbl = $self->{CMNDTABLE};
	while (@_) {
		my $key = shift;
		my $callback = shift;
		unless (exists $tbl->{$key}) {
			$tbl->{$key} = $self->CreateCallback(@$callback);
		} else {
			carp "Command $key already exists"
		}
	}
}

=item B<cmdExecute>('command_name', @options);

Looks for the callback assigned to command_name and executes it.
It first passes the options you specify here. Then it passes the
options you specified in B<cmdConfig>. My advise is to make
a clear choice. Either specify all options here and nothing in
B<cmdConfig>. Or have all the options in B<cmdConfig> and
specify nothing here. This method is called by menu items, toolbar items
and whatever you specify.

=cut

sub cmdExecute {
	my $self = shift;
	my $key = shift;
	my $cmd = $self->{CMNDTABLE}->{$key};
	if (defined $cmd) {
		return $cmd->execute(@_);
	} else {
		carp "Command $key is not defined"
	}
}

=item B<cmdExists>('command_name')

Checks if command_name can be used as a command. Returns 1 or 0.

=cut

sub cmdExists {
	my ($self, $key) = @_;
	unless (defined $key) { return 0 }
	return exists $self->{CMNDTABLE}->{$key};
}

sub CmdGet {
	my ($self, $cmd) = @_;
	return $self->{CMNDTABLE}->{$cmd}
}

sub CmdHook {
	my $self = shift;
	my $method = shift;
	my $cmd = shift;
	my $call = $self->CmdGet($cmd);
	if (defined $call) {
		$call->$method(@_);
		return
	}
	carp "Command '$cmd' does not exist"
}

=item B<cmdHookAfter>(I<'command_name'>, I<@callback>)

Adds a hook to after stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdHookAfter {
	my $self = shift;
	return $self->CmdHook('hookAfter', @_);
}

=item B<cmdHookBefore>(I<'command_name'>, I<@callback>)

Adds a hook to before stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdHookBefore {
	my $self = shift;
	return $self->CmdHook('hookBefore', @_);
}


=item B<cmdRemove>(I<'command_name'>)

Removes 'command_name' from the command stack.

=cut

sub cmdRemove {
	my ($self, $key) = @_;
	return unless defined $key;
	return delete $self->{CMNDTABLE}->{$key};
}

=item B<cmdHookAfter>(I<'command_name'>, I<@callback>)

unhooks a hook from after stack of the callback associated with 'command_name'.
See L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdUnhookAfter {
	my $self = shift;
	return $self->CmdHook('unhookAfter', @_);
}

=item B<cmdHookBefore>(I<'command_name'>, I<@callback>)

unhooks a hook from before stack of the callback associated with 'command_name'.
see L<Tk::AppWindow::BaseClasses::Callback>.

=cut

sub cmdUnhookBefore {
	my $self = shift;
	return $self->CmdHook('unhookBefore', @_);
}

=item B<configGet>I<('-option')>

Equivalent to $app-cget. Except here you can also specify
the options added by B<configInit>

=cut

sub configGet {
	my ($self, $option) = @_;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		return $call->execute;
	} else {
		return $self->cget($option);
	}
}

=item B<configInit>I<(@options)>

 $app->configInit(
    -option1 => ['method', $obj, @options],
    -option2 => [sub { do something }, @options],
 );

Add options to the options table. Usually called at create time. But worth experimenting with.

=cut

sub configInit {
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
			$self->configPut($option, $value);
		} else {
			warn "Config option $option already defined\n";
		}
	}
}

=item B<configMode>

Returns 1 if MainLoop is not yet running.

=cut

sub configMode {
	return exists $_[0]->{ARGS};
}

=item B<configPut>I<(-option => $value)>

Equivalent to $app-configure. Except here you can also specify
the options added by B<configInit>

=cut

sub configPut {
	my ($self, $option, $value) = @_;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		$call->execute($value);
	} else {
		$self->configure($option, $value);
	}
}

=item B<CreateCallback>('MethodName', $owner, @options);

=item B<CreateCallback>(sub { do whatever }, @options);

Creates and returns a Tk::AppWindow::Baseclasses::Callback object. 
A convenience method that saves you some typing.

=cut

sub CreateCallback {
	my $self = shift;
	return Tk::AppWindow::BaseClasses::Callback->new(@_);
}

=item B<extList>

Returns a list of all loaded extensions

=cut

sub extList {
	my $self = shift;
	my $pl = $self->{EXTLOADORDER};
	return @$pl;
}

=item B<extExists('Name')

Returns 1 if 'Name' is loaded.

=cut

sub extExists {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	return exists $plgs->{$name};
}

=item B<extGet>('Name')

Returns reference to extension object 'Name'.
Returns undef if 'Name' is not loaded.

=cut

sub extGet {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	if (exists $plgs->{$name}) {
		return $plgs->{$name}
	}
	return undef
}

=item B<extLoad>('Name');

Loads and initializes an extension.
Terminates application if it fails.

Called at create time.

=cut

sub extLoad {
	my ($self, $name) = @_;
	my $exts = $self->{EXTENSIONS};
	my $ext = undef;
	unless (exists $exts->{$name}) { #unless already loaded
		my $obj;
		my $modname = "Tk::AppWindow::Ext::$name";
		eval "use $modname";
		die $@ if $@;
		$ext = $modname->new($self);
		if (defined($ext)) {
			$self->log("Extension $name loaded\n") if $self->Verbose;
			$exts->{$name} = $ext;
			my $o = $self->{EXTLOADORDER};
			push @$o, $name;
		} else {
			warn "unable to load extension $name\n";
		}
	}
}

sub GetArgsRef { return $_[0]->{ARGS} }

=item B<getArt>I<($icon, $size)>

Checks if extension B<Art> is loaded and returns requested image if so.
If $size is not specified, default size is used.

=cut

sub getArt {
	my ($self, $icon, $size) = @_;
	my $art = $self->extGet('Art');
	if (defined $art) {
		return $art->GetIcon($icon, $size);
	}
	return undef
}

sub log {
	my ($self, $message) = @_;
	$message = "$message\n" unless $message =~ /\n$/;
	$self->Callback('-logcall', $message);
}

sub logError {
	my ($self, $message) = @_;
	$message = "$message\n" unless $message =~ /\n$/;
	$self->Callback('-logerrorcall', $message);
}

=item B<MenuItems>

Returns a list of two items used by the B<MenuBar> plugin. The first defines the application menu.
The second is the menu option Quit in this menu. Overwrite this method to make it return
a different list. See also B<Tk::AppWindow::Ext::MenuBar>

=cut

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd			icon							keyb			config variable
		[	'menu', 				undef,			"~appname", 		], 
		[	'menu_normal',		'appname::',		"~Quit",					'quit',		'application-exit',		'CTRL+Q',	], 
	)
}

sub OSName {
	return $_[0]->{OSNAME}
}

=item B<popMessage>I<($message, $icon, ?$size?)>

Pops up a message box with a close button.

=cut

sub popMessage {
	my ($self, $text, $icon, $size) = @_;
	$icon = 'dialog-information' unless defined $icon;
	$size = 32 unless defined $size;
	my $m = $self->YAMessage(
		-text => $text,
		-image => $self->getArt($icon, $size),
	);
	$m->Show(-popover => $self);
	$m->destroy;
}

sub popTest {
	my $self = shift;
	$self->popMessage('You did something');
}

sub PostConfig {
	my $self = shift;
	delete $self->{ARGS};
	my $lgf = $self->cget('-logo');
	if ((defined $lgf) and (-e $lgf)) {
		my $logo = $self->Photo(-file => $lgf, -format => 'PNG');
		$self->iconimage($logo);
	}
	my $pc = $self->{POSTCONFIG};
	for (@$pc) { $_->execute }

	if ($self->extExists('ConfigFolder') and $self->configGet('-savegeometry')) {
		my $file = $self->configGet('-configfolder') . '/geometry';
		if (open(OFILE, "<", $file)) {
			my $g = <OFILE>;
			close OFILE;
			chomp $g;
			$self->geometry($g);
		} else {
			$self->geometry('600x400+100+100');
		}
	}
}

=item B<ToolItems>

Returns an empty list. It is called by the B<ToolBar> extension. Overwrite it
if you like.

=cut

sub ToolItems {
	my $self = shift;
	return (
	)
}

=item B<Verbose>

Set or get verbosity. Same as $app->configPut(-verbose => $value) or $self->configGet('-verbose');

=cut

sub Verbose {
	my $self = shift;
	$self->{VERBOSE} = shift if @_;
	return $self->{VERBOSE}
}

sub WorkSpace {
	my $self = shift;
	$self->{WORKSPACE} = $self->Subwidget(shift) if @_;
	return $self->{WORKSPACE}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 LICENSE

Same as Perl.

=head1 BUGS

Unknown. Probably plenty. If you find any, please contact the author.

=cut

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::OverView>

=item L<Tk::AppWindow::Ext::Art>

=item L<Tk::AppWindow::Ext::Balloon>

=item L<Tk::AppWindow::Ext::ConfigFolder>

=item L<Tk::AppWindow::Ext::Help>

=item L<Tk::AppWindow::Ext::Keybooard>

=item L<Tk::AppWindow::Ext::MDI>

=item L<Tk::AppWindow::Ext::MenuBar>

=item L<Tk::AppWindow::Ext::Navigator>

=item L<Tk::AppWindow::Ext::Panels>

=item L<Tk::AppWindow::Ext::Plugins>

=item L<Tk::AppWindow::Ext::SDI>

=item L<Tk::AppWindow::Ext::Settings>

=item L<Tk::AppWindow::Ext::StatusBar>

=item L<Tk::AppWindow::Ext::ToolBar>

=back

=cut




1;
__END__
