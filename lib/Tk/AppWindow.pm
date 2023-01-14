package Tk::AppWindow;

=head1 NAME

Tk::AppWindow - an application framework based on Tk

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use Tk::GtkSettings qw(gtkKey initDefaults export2xrdb groupOption);
initDefaults;
my $iconlib = gtkKey('gtk-icon-theme-name');
groupOption('main', 'iconTheme', $iconlib) if defined $iconlib;
export2xrdb;

use base qw(Tk::Derived Tk::MainWindow);
Construct Tk::Widget 'AppWindow';

use File::Basename;
require Tk::AppWindow::BaseClasses::Callback;
require Tk::YAMessage;
require Tk::PNG;

=head1 SYNOPSIS

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=over 4

B<Tk::AppWindow> is a modular application framework written in perl/Tk.
It is a base application that can be extended.
The aim is maximum user configurability and ease of application building.

To get started read L<Tk::AppWindow::OverView>.

This document is a reference manual.

=back

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-appname>

=over 4

Set the name of your application.

If this option is not specified, the name of your application
will be set to the filename of your executable with the first
character in upper case.

=back

=item Switch: B<-commands>

=over 4

Defines commands to be used in your application. It takes a paired list of
command names and callbacks as parameter.

 my $app = $k::AppWindw->new(
    -commands => [
       do_something1 => ['method', $obj],
       do_something2 => sub { return 1 },
    ],
 );

Only available at create time.

=back

=item Name  : B<errorColor>

=item Class : B<ErrorColor>

=item Switch: B<-errorcolor>

=over 4

Default value '#FF0000' (red).

=back

=item Switch: B<-extensions>

=over 4

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

=back

=item Switch: B<-logo>

=over 4

Specifies the image file to be used as logo for your application.
Default value is Tk::findINC('Tk/AppWindow/aw_logo.png').

=back

=item Switch: B<-verbose>

=over 4

Default value is 0.
Set or get verbosity.
Does not do anything at this moment. Meant for logging.

=back

=back

=head1 B<COMMANDS>

=over 4

=item B<quit>

=over 4

Calls the CmdQuit method. See there.

=back

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
	for (@$extensions) {
		$self->LoadExtension($_, $args);
	}
	
	my $setplug = $self->GetExt('Settings');
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

=head1 B<METHODS>

=over 4

=item B<AddPostConfig>I<('Method', $obj, @options)>

=over 4

Only to be called by extensions at create time.
Specifies a callback te be executed after main loop starts.

Callbacks are executed in the order they are added.

=back

=cut

sub AddPostConfig {
	my $self = shift;
	my $pc = $self->{POSTCONFIG};
	my $call = $self->CreateCallback(@_);
	push @$pc, $call
}

=item B<AddPreConfig>I<(@configs)>

=over 4

Only to be called by extensions at create time.
Specifies configs to the ConfigSpec method executed in Populate.

=back

=cut

sub AddPreConfig {
	my $self = shift;
	my $p = $self->{PRECONFIG};
	push @$p, @_
}

=item B<AppName>I<($name)>

=over 4

Sets and returns the application name.
Same as $app->ConfigPut(-name => $name), or $app->ConfigGet($name).

=back

=cut

sub AppName {
	my $self = shift;
	if (@_) { $self->{APPNAME} = shift }
	return $self->{APPNAME}
}

=item B<CanQuit>

=over 4

returns 1. It is called when Tk::AppWindow tests all extensions if they can quit. You can 
overwrite it when you inherit Tk::AppWindow.

=back

=cut

sub CanQuit {
	return 1
}

=item B<CmdQuit>

=over 4

Gets called when you execute the 'quit' command or close the main window.
It queries all extensions for permission and exits if all cleanr.

=back

=cut

sub CmdQuit {
	my $self = shift;
	my $quit = 1;
	my $plgs = $self->{EXTENSIONS};
	for (keys %$plgs) {
		$quit = 0 unless $plgs->{$_}->CanQuit;
	}
	$quit = 0 unless $self->CanQuit;
	if ($quit) {
		$self->destroy;
	} 
}

=item B<CommandsConfig>I<(@commands)>

=over 4

 $app->CommandsConfig(
    command1 => ['SomeMethod', $obj, @options],
    command2 => [sub { do whatever }, @options],
 );

CommandsConfig takes a paired list of commandnames and callback descriptions.
It registers them to the commands table. After that B<CommandExecute> can 
be called on them.

=back

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

=over 4

Looks for the callback assigned to command_name and executes it.
It first passes the options you specify here. Then it passes the
options you specified in B<CommandsConfig>. My advise is to make
a clear choice. Either specify all options here and nothing in
B<CommandsConfig>. Or have all the options in B<CommandsConfig> and
specify nothing here. This method is called by menu items, toolbar items
and whatever you specify.

=back

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

=over 4

Checks if command_name can be used as a command. Returns 1 or 0.

=back

=cut

sub CommandExists {
	my ($self, $key) = @_;
	unless (defined $key) { return 0 }
	return exists $self->{CMNDTABLE}->{$key};
}

sub CommandRegister {
	my ($self, $key, $callback) = @_;
	my $tbl = $self->{CMNDTABLE};
	unless (exists $tbl->{$key}) {
		$tbl->{$key} = $self->CreateCallback(@$callback);
	} else {
		warn "Command $key already exists"
	}
}

=item B<ConfigGet>I<('-option')>

=over 4

Equivalent to $app-cget. Except here you can also specify
the options added by B<ConfigInit>

=back

=cut

sub ConfigGet {
	my ($self, $option) = @_;
	if (exists $self->{CONFIGTABLE}->{$option}) {
		my $call = $self->{CONFIGTABLE}->{$option};
		return $call->Execute;
	} else {
		return $self->cget($option);
	}
}

=item B<ConfigInit>I<(@options)>

=over 4

 $app->ConfigInit(
    -option1 => ['method', $obj, @options],
    -option2 => [sub { do something }, @options],
 );

Add options to the options table. Usually called at create time. But worth experimenting with.

=back

=cut

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

=item B<ConfigMode>

=over 4

Returns 1 if MainLoop is not yet running.

=back

=cut

sub ConfigMode {
	return exists $_[0]->{ARGS};
}

=item B<ConfigPut>I<(-option => $value)>

=over 4

Equivalent to $app-configure. Except here you can also specify
the options added by B<ConfigInit>

=back

=cut

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

=over 4

Creates and returns a Tk::AppWindow::Baseclasses::Callback object. 
A convenience method that saves you some typing.

=back

=cut

sub CreateCallback {
	my $self = shift;
	return Tk::AppWindow::BaseClasses::Callback->new(@_);
}

=item B<ExtensionList>

=over 4

Returns a list of all loaded extensions

=back

=cut

sub ExtensionList {
	my $self = shift;
	my $pl = $self->{EXTLOADORDER};
	return @$pl;
}

sub GetArgsRef { return $_[0]->{ARGS} }

=item B<GetArt>I<($icon, $size)>

=over 4

Checks if extension B<Art> is loaded and returns requested image if so.
If $size is not specified, default size is used.

=back

=cut

sub GetArt {
	my ($self, $icon, $size) = @_;
	my $art = $self->GetExt('Art');
	if (defined $art) {
		return $art->GetIcon($icon, $size);
	}
	return undef
}

=item B<GetExt>('Name')

Returns reference to extension object 'Name'.
Returns undef if 'Name' is not loaded.

=cut

sub GetExt {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	if (exists $plgs->{$name}) {
		return $plgs->{$name}
	}
	return undef
}

=item B<LoadExtension>('Name');

=over 4

Loads and initializes an extension.
Terminates application if it fails.

Called at create time.

=back

=cut

sub LoadExtension {
	my ($self, $name) = @_;
	my $plgs = $self->{EXTENSIONS};
	my $plug = undef;
	unless (exists $plgs->{$name}) { #unless already loaded
		my $obj;
		my $modname = "Tk::AppWindow::Ext::$name";
		eval "use $modname";
		die $@ if $@;
		$plug = $modname->new($self);
		if (defined($plug)) {
			print "Extension $name loaded\n" if $self->Verbose;
			$plgs->{$name} = $plug;
			my $o = $self->{EXTLOADORDER};
			push @$o, $name;
		} else {
			warn "unable to load extension $name\n";
		}
	}
}

=item B<MenuItems>

=over 4

Returns a list of two items used by the B<MenuBar> plugin. The first defines the application menu.
The second is the menu option Quit in this menu. Overwrite this method to make it return
a different list. See also B<Tk::AppWindow::Ext::MenuBar>

=back

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

=item B<PopMessage>I<($message, $icon, ?$size?)>

=over 4

Pops up a message box with a close button.

=back

=cut

sub PopMessage {
	my ($self, $text, $icon, $size) = @_;
	$icon = 'dialog-information' unless defined $icon;
	$size = 32 unless defined $size;
	my $m = $self->YAMessage(
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
	delete $self->{ARGS};
   my $lgf = $self->cget('-logo');
   if ((defined $lgf) and (-e $lgf)) {
      my $logo = $self->Photo(-file => $lgf, -format => 'PNG');
      $self->iconphoto($logo);
   }
	my $pc = $self->{POSTCONFIG};
	for (@$pc) { $_->Execute }
}

=item B<ToolItems>

=over 4

Returns an empty list. It is called by the B<ToolBar> extension. Overwrite it
if you like.

=back

=cut

sub ToolItems {
	my $self = shift;
	return (
	)
}

=item B<Verbose>

=over 4

Set or get verbosity. Same as $app->ConfigPut(-verbose => $value) or $self->ConfigGet('-verbose');

=back

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

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back

=cut

=head1 BUGS

Unknown. Probably plenty. If you find any, please contact the author.

=cut

=head1 TODO

=over 4


=back

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
