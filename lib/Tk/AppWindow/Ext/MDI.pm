package Tk::AppWindow::Ext::MDI;

=head1 NAME

Tk::AppWindow::Ext::MDI - multiple document interface

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.02";

use base qw( Tk::AppWindow::BaseClasses::Extension );

use File::Basename;
use File::Spec;
use File::stat;
use Time::localtime;
require Tk::YAMessage;
require Tk::YANoteBook;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a multi document interface to your application.

When L<Tk::AppWindow::Ext::MenuBar> is loaded it creates menu 
entries for creating, opening, saving and closing files. It also
maintains a history of recently closed files.

When L<Tk::AppWindow::Ext::ToolBar> is loaded it creates toolbuttons
for creating, opening, saving and closing files.

It features deferred loading. If you open a document it will not load the document
until there is a need to access it. This comes in handy when you want
to open multiple documents at one time.

You should define a content handler based on the abstract
baseclass L<Tk::AppWindow::BaseClasses::ContentManager>. See also there.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-contentmanagerclass>

This one should always be specified and you should always define a 
content manager class inheriting L<Tk::AppWindow::BaseClasses::ContentManager>.
This base class is a valid Tk widget.

=item Switch: B<-contentmanageroptions>

The possible options to pass on to the contentmanager.
These will also become options to the main application.

=item Switch: B<-filetypes>

Default value is "All files|*"

=item Switch: B<-historymenupath>

Specifies the default location in the main menu of the history menu.
Default value is File::Open recent. See also L<Tk::AppWindow::Ext::MenuBar>.

=item Switch: B<-maxhistory>

Default value is 12.

=item Switch: B<-maxtablength>

Default value 16

Maximum size of the document tab in the document bar.

=item Switch: B<-monitorinterval>

Default value 3 seconds. Specifies the interval for
the monitor cycle. This cycle monitors loaded files
for changes on disk and modified status.

=item Switch: B<-readonly>

Default value 0. If set to 1 MDI will operate in read only mode.

=back

=head1 COMMANDS

The following commands are defined.

=over 4

=item B<doc_close>

Takes a document name as parameter and closes it.
If no parameter is specified closes the current selected document.
Returns a boolean for succes or failure.

=item B<doc_new>

Takes a document name as parameter and creates a new content handler for it.
If no parameter is specified and Untitled document is created.
Returns a boolean for succes or failure.

=item B<doc_open>

Takes a filename name as parameter and opens it.
If no parameter is specified a file dialog is issued.
Returns a boolean for succes or failure.

=item B<doc_save>

Takes a document name as parameter and saves it if it is modified.
If no parameter is specified the current selected document is saved.
Returns a boolean for succes or failure.

=item B<doc_save_as>

Takes a document name as parameter and issues a file dialog to rename it.
If no parameter is specified the current selected document is initiated in the dialog.
Returns a boolean for succes or failure.

=item B<doc_save_all>

Saves all open and modified documents.
Returns a boolean for succes or failure.

=item B<pop_hist_menu>

Is called when the file menu is opened in the menubar. It populates the
'Open recent' menu with the current history.

=item B<set_title>

Takes a document name as parameter and sets the main window title accordingly.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require( qw[ConfigFolder] );

	$self->{CMOPTIONS} = {};
	$self->{DEFERRED} = {};
	$self->{DOCS} = {};
	$self->{FORCECLOSE} = 0;
	$self->{HISTORY} = [];
	$self->{INTERFACE} = undef;
	$self->{MONITOR} = {};
	$self->{NOCLOSEBUTTON} = 0;
	$self->{SELECTDISABLED} = 0;
	$self->{SELECTED} = undef;

	my $args = $self->GetArgsRef;
	my $cmo = delete $args->{'-contentmanageroptions'};
	$cmo = [] unless defined $cmo;
	my @preconfig = ();
	for (@$cmo) {
		push @preconfig, $_ => ['PASSIVE', undef, undef, ''];
	}

	$self->addPreConfig(@preconfig,
		-contentmanagerclass => ['PASSIVE', undef, undef, 'Wx::Perl::FrameWorks::BaseClasses::ContentManager'],
		-contentmanageroptions => ['PASSIVE', undef, undef, $cmo],
		-maxhistory => ['PASSIVE', undef, undef, 12],
		-filetypes => ['PASSIVE', undef, undef, "All files|*"],
		-historymenupath => ['PASSIVE', undef, undef, 'File::Open recent'],
		-maxtablength => ['PASSIVE', undef, undef, 16],
		-monitorinterval => ['PASSIVE', undef, undef, 3], #seconds
		-readonly => ['PASSIVE', undef, undef, 0],
	);
	$self->cmdConfig(
		doc_close => ['CmdDocClose', $self],
		doc_new => ['CmdDocNew', $self],
		doc_open => ['CmdDocOpen', $self],
		doc_save => ['CmdDocSave', $self],
		doc_save_as => ['CmdDocSaveAs', $self],
		$self->CommandDocSaveAll,
		set_title => ['setTitle', $self],
		pop_hist_menu => ['CmdPopulateHistoryMenu', $self],
	);

	$self->addPostConfig('DoPostConfig', $self);
	$self->historyLoad;
	return $self;
}

=head1 METHODS

=over 4

=cut

sub CanQuit {
	my $self = shift;
	if ($self->docConfirmSaveAll) {
		$self->docForceClose(1);
		return 1
	}
	return 0
}

sub CmdCloseButtonPressed {
	my ($self, $name) =  @_;
	my $close = 1;
	return $close if exists $self->{NOCLOSEBUTTON};
	if ($self->docConfirmSave($name)) {
		$close = $self->docClose($name);
		$self->interfaceRemove($name, 0) if $close;
	}
	return $close
}

sub CmdDocClose {
	my ($self, $name) =  @_;
	$name = $self->docSelected unless defined $name;
	return 1 unless defined $name;
	my $close = 1;
	$self->{NOCLOSEBUTTON} = 1;
	my $fc = $self->docForceClose;
	my $cs = $self->docConfirmSave($name);	
	if ($self->docForceClose or $self->docConfirmSave($name)) {
		my $geosave = $self->geometry;
		$close = $self->docClose($name);
		$self->interfaceRemove($name) if $close;
		$self->geometry($geosave);
	}
	delete $self->{NOCLOSEBUTTON};
	$self->log("Closed '$name'") if $close;
	$self->logWarning("Failed closing '$name'") unless $close;
	return $close
}


sub CmdDocNew {
	my ($self, $name) = @_;
	$name = $self->docUntitled unless defined $name;
	$self->deferredAssign($name);
	$self->interfaceAdd($name);

	$self->docSelect($name);
	return 1;
}

sub CmdDocOpen {
	my ($self, $file) = @_;
	unless (defined($file)) {
		my @op = ();
		@op = (-popover => 'mainwindow') unless $self->OSName eq 'MSWin32';
		my $sel = $self->docSelected;
		push @op, -initialdir => dirname($sel) if defined $sel;
		$file = $self->getOpenFile(@op);
	}
	if (defined $file) {
		if ($self->docExists($file)) {
			$self->docSelect($file);
			return 1
		}
		my $file = File::Spec->rel2abs($file);
		if ($self->cmdExecute('doc_new', $file)) {
			$self->historyRemove($file);
			$self->docSelect($file);
			$self->log("Opened '$file'");
		}
		return 1
	}
 	return 0
}

sub CmdDocSave {
	my ($self, $name) = @_;
	return 1 if $self->configGet('-readonly');
	$name = $self->docSelected unless defined $name;
	return 1 unless defined $name;
	return 1 unless $self->docModified($name);
	
	my $doc = $self->docGet($name);

	if (defined $doc) {
		unless ($name =~ /^Untitled/) {
			if ($doc->Save($name)) {
				$self->log("Saved '$name'");
				$self->monitorUpdate($name);
				return 1
			} else {
				$self->logWarning("Failed saving '$name'");
				return 0
			}
			
		} else {
			return $self->CmdDocSaveAs($name);
		}
	}
	return 0
}

sub CmdDocSaveAs {
	my ($self, $name) = @_;
	return 0 if $self->configGet('-readonly');
	$name = $self->docSelected unless defined $name;
	return 0 unless defined $name;

	my $doc = $self->docGet($name);
	if (defined $doc) {
		my @op = (-initialdir => dirname($name));
		push @op, -popover => 'mainwindow' unless $self->OSName eq 'MSWin32';
		my $file = $self->getSaveFile(@op,);
		if (defined $file) {
			$file = File::Spec->rel2abs($file);
			if ($doc->Save($file)) {
				$self->log("Saved '$file'");
				$self->docRename($name, $file);
				return 1
			} else {
				$self->logWarning("Failed saving '$file'");
				return 0
			}
		}
	}
	return 0
}

sub CmdDocSaveAll {
	my $self = shift;
	my @list = $self->docList;
	my $succes = 1;
	for (@list) {
		$succes = 0 unless $self->cmdExecute('doc_save', $_)
	}
	return $succes
}

sub CmdPopulateHistoryMenu {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	if (defined $mnu) {
		my $path = $self->configGet('-historymenupath');
		my ($menu, $index) = $mnu->FindMenuEntry($path);
		if (defined($menu)) {
			my $submenu = $menu->entrycget($index, '-menu');
			$submenu->delete(1, 'last');
			my $h = $self->{HISTORY};
			for (@$h) {
				my $f = $_;
				$submenu->add('command',
					-label => $f,
					-command => sub { $self->CmdDocOpen($f) }
				);
			}
			$submenu->add('separator');
			$submenu->add('command',
				-label => 'Clear list',
				-command => sub { @$h = () },
			);
		}
	}
}

sub CommandDocSaveAll {
	my $self = shift;
	return doc_save_all => ['CmdDocSaveAll', $self],
}

=item B<ConfirmSaveDialog>I<($name)>

Pops a dialog with a warning that $name is unsaved.
Asks for your action. Does not check if $name is modified or not.
Returns the key you press, 'Yes', 'No', or cancel.
Does not do any saving or checking whether a file has been modified.

=cut

sub ConfirmSaveDialog {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $title = 'Warning, file modified';
	my $text = 	"Closing " . basename($name) .
		".\nDocument has been modified. Save it?";
	my $icon = 'dialog-warning';
	return $self->popDialog($title, $text, $icon, qw/Yes No Cancel/);
}

=item B<ContentSpace>I<($name)>

Returns the page frame widget in the notebook belonging to $name.

=cut

sub ContentSpace {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return $self->Interface->getPage($name);
}

=item B<CreateContentHandler>I($name);

Initiates a new content handler for $name.

=cut

sub CreateContentHandler {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $page = $self->ContentSpace($name);
	my $cmclass = $self->configGet('-contentmanagerclass');
	my $h = $page->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
	$self->{DOCS}->{$name} = $h;
	return $h;
}

=item B<CreateInterface>

Creates a Tk::YANoteBook multiple document interface.

=cut

sub CreateInterface {
	my $self = shift;
	$self->{INTERFACE} = $self->WorkSpace->YANoteBook(
		-selecttabcall => ['docSelect', $self],
		-closetabcall => ['CmdCloseButtonPressed', $self],
	)->pack(-expand => 1, -fill => 'both');
}

=item B<deferredAssign>I<($name, ?$options?)>

This method is called when you open a document.
It adds document $name to the interface and stores $options
in the deferred hash. $options is a reference to a hash. It's keys can
be any option accepted by your content manager.

=cut

sub deferredAssign {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	$options = {} unless defined $options;
	$self->{DEFERRED}->{$name} = $options;
}

=item B<deferredExists>I<($name)>

Returns true if deferred entry $name exists.

=cut

sub deferredExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return exists $self->{DEFERRED}->{$name}
}

=item B<deferredOpen>I<($name)>

This method is called when you access the document for the first time.
It creates the content manager with the deferred options and loads the file.

=cut

sub deferredOpen {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $doc = $self->CreateContentHandler($name);
	my $flag = 1;
	$flag = 0 unless (-e $name) and ($doc->Load($name));
	my $options = $self->deferredOptions($name);
	$self->after(20, sub {
		for (keys %$options) {
			$doc->configure($_, $options->{$_})
		}
		$self->monitorAdd($name);
	});
	$self->deferredRemove($name);
	if ($flag) {
		$self->log("Loaded $name");
	} else {
		$self->logWarning("Failed loading $name");
	}
	return $flag
}

=item B<deferredOptions>I<($name, ?$options?)>

Sets and returns a reference to the hash containing the
options for $name.

=cut

sub deferredOptions {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	my $def = $self->{DEFERRED};
	$def->{$name} = $options if defined $options;
	return $def->{$name} 
}

=item B<deferredRemove>I<($name)>

Removes $name from the deferred hash.

=cut

sub deferredRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	delete $self->{DEFERRED}->{$name}
}

=item B<docClose>I<($name)>

Removes $name from the interface and destroys the content manager.
Also adds $name to the history list.

=cut

sub docClose {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	if ($self->deferredExists($name)) {
		$self->historyAdd($name);
		$self->deferredRemove($name);
		return 1
	}
	my $doc = $self->docGet($name);
	if ($doc->Close) {
		#Add to history
		$self->historyAdd($name);

		#delete from document hash
		delete $self->{DOCS}->{$name};
		$self->monitorRemove($name);

		if ((defined $self->docSelected) and ($self->docSelected eq $name)) { 
			$self->docSelected(undef);
		}
		$doc->destroy;
		return 1
	}
	return 0
}

=item B<docConfirmSave>I<($name)>

Checks if $name is modified and asks confirmation
for save. Saves the document if you press 'Yes'.
Returns 1 unless you cancel the dialog, then it returns 0.
 
=cut

sub docConfirmSave {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	if ($self->docModified($name)) {
		#confirm save dialog comes here
		my $answer = $self->ConfirmSaveDialog($name);
		if ($answer eq 'Yes') {
			return 0 unless $self->cmdExecute('doc_save', $name);
		} elsif ($answer eq 'No') {
			return 1
		} else {
			return 0
		}
	} else {
		return 1
	}
}

=item B<docConfirmSaveAll>

Calls docConfirmSave for all loaded documents.
returns 0 if a 'Cancel' is detected.

=cut

sub docConfirmSaveAll {
	my $self = shift;
	my $close = 1;
	my @docs = $self->docList;
	for (@docs) {
		my $name = $_;
		$close = $self->docConfirmSave($name);
		last if $close eq 0;
	}
	return $close;
}

=item B<docExists>I<($name)>

Returns true if $name exists in either loaded or deferred state.

=cut

sub docExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 1 if exists $self->{DOCS}->{$name};
	return 1 if $self->deferredExists($name);
	return 0
}

=item B<docForceClose>I<(?$flag?)>

If $flag is set ConfirmSave dialogs will be skipped,
documents will be closed ruthlessly. Use with care
and always reset it back to 0 when you're done.

=cut

sub docForceClose {
	my $self = shift;
	if (@_) { $self->{FORCECLOSE} = shift }
	return $self->{FORCECLOSE}
}

=item B<docGet>I<($name)>

Returns the content manager object for $name.

=cut

sub docGet {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$self->deferredOpen($name) if $self->deferredExists($name);
	return $self->{DOCS}->{$name}
}

=item B<docList>

Returns a list of all loaded documents.

=cut

sub docList {
	my $self = shift;
	my $dochash = $self->{DOCS};
	return keys %$dochash;
}

=item B<docModified>I<($name)>

Returns true if $name is modified.

=cut

sub docModified {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 0 if $self->deferredExists($name);
	return $self->docGet($name)->IsModified;
}

=item B<docRename>I<($old, $new)>

Renames a loaded document.

=cut

sub docRename {
	my ($self, $old, $new) = @_;
	croak 'Old not defined' unless defined $old;
	croak 'New not defined' unless defined $new;

	unless ($old eq $new) {
		my $doc = delete $self->{DOCS}->{$old};
		$self->{DOCS}->{$new} = $doc;

		$self->interfaceRename($old, $new);
		$self->monitorRemove($old);
		$self->monitorAdd($new);

		if ($self->docSelected eq $old) {
			$self->docSelect($new)
		}
	}
}

=item B<docSelect>I<($name)>

Selects $name.

=cut

sub docSelect {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return if $self->selectDisabled;
	$self->deferredOpen($name) if $self->deferredExists($name);
	$self->docSelected($name);
	$self->interfaceSelect($name);
	$self->docGet($name)->doSelect;
	$self->cmdExecute('set_title', $name);
}

=item B<docSelected>

Returns the name of the currently selected document.
Returns undef if no document is selected.

=cut

sub docSelected {
	my $self = shift;
	$self->{SELECTED} = shift if @_;
	return $self->{SELECTED}
}

=item B<docTitle>I<($name)>

Strips the path from $name for the title bar.

=cut

sub docTitle {
	my ($self, $name) = @_;
	return basename($name, '');
}

=item B<docUntitled>>

Returns 'Untitled' plus a digit '(d)'.
It checks how many untitled documents exists
and adjusts the number.

=cut

sub docUntitled {
	my $self = shift;
	my $name = 'Untitled';
	if ($self->docExists($name)) {
		my $num = 2;
		while ($self->docExists("$name ($num)")) { $num ++ }
		$name = "$name ($num)";
	}
	return $name
}

sub DoPostConfig {
	my $self = shift;
	$self->CreateInterface;
	$self->monitorCycleStart;
}

=item B<historyAdd>I<($name)>

=cut

sub historyAdd {
	my ($self, $filename) = @_;
	croak 'Name not defined' unless defined $filename;
	if (defined($filename) and (-e $filename)) {
		my $hist = $self->{HISTORY};
		unshift @$hist, $filename;

		#Keep history size at or below maximum
		my $siz = @$hist;
		pop @$hist if ($siz > $self->configGet('-maxhistory'));
	}
}

=item B<historyLoad>

Loads the history file in the config folder.

=cut

sub historyLoad {
	my $self = shift;
	my $folder = $self->configGet('-configfolder');
	if (-e "$folder/history") {
		if (open(OFILE, "<", "$folder/history")) {
			my @history = ();
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				push @history, $line;
			}
			close OFILE;
			$self->{HISTORY} = \@history;
		}
	}
}

=item B<historyRemove>I<($name)>

Removes $name from the history list. Called when a document is
opened.

=cut

sub historyRemove {
	my ($self, $file) = @_;
	croak 'Name not defined' unless defined $file;
	my $h = $self->{HISTORY};
	my ($index) = grep { $h->[$_] eq $file } (0 .. @$h-1);
	splice @$h, $index, 1 if defined $index;
}

=item B<historySave>

Saves the history list to the history file in the config folder.

=cut

sub historySave {
	my $self = shift;
	my $hist = $self->{HISTORY};
	if (@$hist) {
		my $folder = $self->configGet('-configfolder');
		if (open(OFILE, ">", "$folder/history")) {
			for (@$hist) {
				print OFILE "$_\n";
			}
			close OFILE
		} else {
			warn "Cannot save document history"
		}
	}
}

=item B<Interface>

Returns a reference to the multiple document interface.

=cut

sub Interface {
	return $_[0]->{INTERFACE}
}

=item B<interfaceAdd>I<($name)>

Adds $name to the multiple document interface and to the
Navigator if the Navigator extension is loaded.

=cut

sub interfaceAdd {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	#add to document notebook
	my $if = $self->Interface;
	if (defined $if) {
		my @op = ();
		my $cti = $self->getArt('tab-close', 16);
		push @op, -closeimage => $cti if defined $cti;
		my $page = $if->addPage($name, @op,
			-title => $self->docTitle($name),
			-closebutton => 1,
		);
	}

	#add to navigator
	my $navigator = $self->extGet('Navigator');
	$navigator->Add($name) if defined $navigator;
}

=item B<interfaceRemove>I<($name, ?$flag?)>

Removes $name from the multiple document interface and from the
Navigator if the Navigator extension is loaded.

=cut

sub interfaceRemove {
	my ($self, $name, $flag) = @_;
	croak 'Name not defined' unless defined $name;
	$flag = 1 unless defined $flag;
	#remove from document notebook
	my $if = $self->Interface;
	$if->deletePage($name) if (defined $if) and $flag;

	#remove from navigator
	my $navigator = $self->extGet('Navigator');
	$navigator->Delete($name) if defined $navigator;
}

=item B<interfaceRename>I<($old, $new)>

Renames the $old entry in the multiple document interface and the navigator.

=cut

sub interfaceRename {
	my ($self, $old, $new) = @_;
	croak 'Old not defined' unless defined $old;
	croak 'New not defined' unless defined $new;

	#rename in document notebook
	my $if = $self->Interface;
	if (defined $if) {
		$if->renamePage($old, $new);
		my $tab = $if->getTab($new);
		$tab->configure(
			-name => $new,
			-title => $self->docTitle($new),
		);
	}

	#rename in navigator
	my $navigator = $self->extGet('Navigator');
	if (defined $navigator) {
		$navigator->Delete($old);
		$navigator->Add($new);
	}
}

=item B<interfaceSelect>I<($name)>

Is called when something else than the user selects a document.

=cut

sub interfaceSelect {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	#select on document notebook
	my $if = $self->Interface;
	$if->selectPage($name) if defined $if;

	#select on  navigator
	my $navigator = $self->extGet('Navigator');
	$navigator->SelectEntry($name) if defined $navigator;
}

=item B<MenuItems>

Returns the menu items for MDI. Called by extension B<MenuBar>.

=cut

sub MenuSaveAll {
	my $self = shift;
	return [	'menu_normal', 'File::', "Save ~all", 'doc_save_all', 'document-save', 'CTRL+L'],
}

sub MenuItems {
	my $self = shift;
	my $readonly = $self->configGet('-readonly');

	my @items = (
#        type              menupath       label                cmd                  icon              keyb
 		[	'menu', 				undef,			"~File" 	], 
	);
	push @items,
		[	'menu_normal',		'File::',		"~New",					'doc_new',				'document-new',	'CTRL+N'			], 
		[	'menu_separator',	'File::', 		'f1'], 
	unless $readonly;
	push @items,
		[	'menu_normal',		'File::',		"~Open",					'doc_open',			'document-open',	'CTRL+O'			], 
 		[	'menu', 				'File::',		"Open ~recent", 		'pop_hist_menu', 	],
	;
	push @items,
		[	'menu_separator',	'File::', 		'f2' ], 
		[	'menu_normal',		'File::',		"~Save",					'doc_save',			'document-save',	'CTRL+S'			], 
		[	'menu_normal',		'File::',		"S~ave as",				'doc_save_as',		'document-save-as',],
		$self->MenuSaveAll,
	unless $readonly;
	push @items,
		[	'menu_separator',	'File::', 		'f3' ], 
		[	'menu_normal',		'File::',		"~Close",				'doc_close',			'document-close',	'CTRL+SHIFT+O'	], 
	;
	return @items
}

=item B<monitorAdd>I<($name)>

Adds $name to the hash of monitored documents.
It will check it's modified status. It willcollect its time stamp, 
if $name is an existing file.

=cut

sub monitorAdd {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $hash = $self->{MONITOR};
#	print "adding $name, ";
	my $modified = $self->docModified($name);
	my $stamp;
	$stamp = ctime(stat($name)->mtime) if -e $name;
#	print "$modified, $stamp";
	$hash->{$name} = {
		modified => $modified,
		timestamp => $stamp,
	}
}

=item B<monitorCycle>

This method is called every time the monitor interval times out.
It will check all monitored files for changes on disk and checks
if they should be marked ad modified or saved in the navigator.

=cut

sub monitorCycle {
	my $self = shift;
	my @list = $self->monitorList;
	for (@list) {
		my $name = $_;
		$self->monitorDisk($name);
		$self->monitorModified($name);
	}
	$self->monitorCycleStart;
}

=item B<monitorCycleStart>

Starts the timer for B<monitorCycle>. The value of the
timer is specified in the B<-monitorinterval> option.

=cut

sub monitorCycleStart {
	my $self = shift;
	my $interval = $self->configGet('-monitorinterval') * 1000;
	$self->after($interval, ['monitorCycle', $self]);
}

=item B<monitorDisk>I<($name)>

Checks if $name is modified on disk after it was loaded.
Launches a dialog for reload or ignore if so.

=cut

sub monitorDisk {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return unless -e $name;
	my $stamp = $self->{MONITOR}->{$name}->{'timestamp'};
	my $docstamp = ctime(stat($name)->mtime);
	if ($stamp ne $docstamp) {
		my $title = 'Warning, file modified on disk';
		my $text = 	"$name\nHas been modified on disk.";
		my $icon = 'dialog-warning';
		my $answer = $self->popDialog($title, $text, $icon, qw/Reload Ignore/);
		if ($answer eq 'Reload') {
			$self->docGet($name)->Load($name);
		}
		$self->{MONITOR}->{$name}->{'timestamp'} = $docstamp;
	}
}

=item B<monitorList>I<($name)>

returns a list of monitored documents.

=cut

sub monitorList {
	my $self = shift;
	my $hash = $self->{MONITOR};
	return sort keys %$hash;
}

=item B<monitorModified>I<($name)>

Checks if the modified status of the document has changed
and updates the navigator.

=cut

sub monitorModified {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	my $mod = $self->{MONITOR}->{$name}->{'modified'};
	my $docmod = $self->docModified($name);
	my $nav = $self->extGet('Navigator');
	if ($mod ne $docmod) {
		if ($docmod) {
			$nav->EntryModified($name) if defined $nav;
		} else {
			$nav->EntrySaved($name) if defined $nav;
		}
		$self->{MONITOR}->{$name}->{'modified'} = $docmod;
	}
}

=item B<monitorRemove>I<($name)>

Removes $name from the hash of monitored documents.

=cut

sub monitorRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	delete $self->{MONITOR}->{$name};
}

=item B<monitorUpdate>I<($name)>

Assigns a fresh time stamp to $name. Called when a document is saved.

=cut

sub monitorUpdate {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	$self->{MONITOR}->{$name}->{'timestamp'} = ctime(stat($name)->mtime);
}

sub ReConfigure {
	my $self = shift;
	my @docs = $self->docList;
	for (@docs) {
		$self->docGet($_)->ConfigureCM;
	}
}

sub Quit {
	my $self = shift;
	my @docs = $self->docList;
# 	$self->docForceClose(1);
	for (@docs) {
		$self->CmdDocClose($_);
	}
	$self->historySave;
}

=item B<selectDisabled>I<?$flag?)>

Sets and returns the selectdisabled flag. If this flag is set,
no document can be selected. Use with care.

=cut

sub selectDisabled {
	my $self = shift;
	if (@_) { $self->{SELECTDISABLED} = shift }
	return $self->{SELECTDISABLED}
}

sub setTitle {
	my ($self, $name) = @_;
	my $appname = $self->configGet('-appname');
	$self->configPut(-title => "$name - $appname") if defined $name;
	$self->configPut(-title => $appname) unless defined $name;
}


=item B<ToolItems>

Returns the tool items for MDI. Called by extension B<ToolBar>.

=cut

sub ToolItems {
	my $self = shift;
	my $readonly = $self->configGet('-readonly');
	my @items = ();

	push @items,
		#	 type					label			cmd					icon					help		
		[	'tool_button',		'New',		'doc_new',			'document-new',	'Create a new document'],
	unless $readonly;

	push @items,
		[	'tool_button',		'Open',		'doc_open',		'document-open',	'Open a document'], 
	;

	push @items,
		[	'tool_button',		'Save',		'doc_save',		'document-save',	'Save current document'], 
	unless $readonly;

	push @items,
		[	'tool_button',		'Close',		'doc_close',		'document-close',	'Close current document'], 
	; 
	return @items
}


=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::BaseClasses::ContentManager>

=item L<Tk::AppWindow::Ext::ConfigFolder>

=item L<Tk::AppWindow::Ext::Navigator>

=back

=cut

1;















