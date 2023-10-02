package Tk::AppWindow::Ext::MDI;

=head1 NAME

Tk::AppWindow::Ext::MDI - multiple document interface

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

require Tk::YANoteBook;
use File::Basename;
use File::Spec;
require Tk::YAMessage;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['MDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a multi document interface to your application,
Inherites L<Tk::AppWindow::Ext::SDI>.

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-maxtablength>

Default value 16

Maximum size of the document tab in the document bar.

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
		-readonly => ['PASSIVE', undef, undef, 0],
	);
	$self->cmdConfig(
		doc_new => ['CmdDocNew', $self],
		doc_open => ['CmdDocOpen', $self],
		doc_save => ['CmdDocSave', $self],
		doc_save_as => ['CmdDocSaveAs', $self],
		$self->CommandDocSaveAll,
		doc_close => ['CmdDocClose', $self],
		set_title => ['setTitle', $self],
		pop_hist_menu => ['CmdPopulateHistoryMenu', $self],
	);

	$self->addPostConfig('CreateInterface', $self);
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
}

sub CmdDocClose {
	my ($self, $name) =  @_;
	$name = $self->docSelected unless defined $name;
	return 1 unless defined $name;
	my $close = 1;
	if ($self->docForceClose or $self->docConfirmSave($name)) {
		my $geosave = $self->geometry;
		$close = $self->docClose($name);
		if ($close) {
			$self->interfaceRemove($name);
			return 1
		}
		$self->geometry($geosave);
	}
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

sub ConfirmSaveDialog {
	my ($self, $name) = @_;
	my $title = 'Warning, file modified';
	my $text = 	"Closing " . basename($name) .
		".\nDocument has been modified. Save it?";
	my $icon = 'dialog-warning';
	return $self->popDialog($title, $text, $icon, qw/Yes No Cancel/);
}

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
# 		-closetabcall => ['docClose', $self],
	)->pack(-expand => 1, -fill => 'both');
}

sub deferredAssign {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	$options = {} unless defined $options;
	$self->{DEFERRED}->{$name} = $options;
}

sub deferredExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return exists $self->{DEFERRED}->{$name}
}

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
	});
	$self->deferredRemove($name);
	if ($flag) {
		$self->log("Loaded $name");
	} else {
		$self->logWarning("Failed loading $name");
	}
	return $flag
}

sub deferredOptions {
	my ($self, $name, $options) = @_;
	croak 'Name not defined' unless defined $name;
	my $def = $self->{DEFERRED};
	$def->{$name} = $options if defined $options;
	return $def->{$name} 
}

sub deferredRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	delete $self->{DEFERRED}->{$name}
}

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

		if ((defined $self->docSelected) and ($self->docSelected eq $name)) { 
			$self->docSelected(undef);
		}
		$doc->destroy;
		return 1
	}
	return 0
}

sub docConfirmSave {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	if ($self->docModified($name)) {
		#confirm save dialog comes here
		my $answer = $self->ConfirmSaveDialog($name);
		if ($answer eq 'Yes') {
			return 0 unless $self->cmdExecute('doc_save', $name);
		} elsif ($answer eq 'Cancel') {
			return 0
		}
	}
	return 1
}

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

sub docExists {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 1 if exists $self->{DOCS}->{$name};
	return 1 if $self->deferredExists($name);
	return 0
}

sub docForceClose {
	my $self = shift;
	if (@_) { $self->{FORCECLOSE} = shift }
	return $self->{FORCECLOSE}
}

=item B<docGet>I<($name)

Returns document object for $name.

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

sub docModified {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;
	return 0 if $self->deferredExists($name);
	return $self->docGet($name)->IsModified;
}

=item B<docRename>I<($old, $new)

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

		if ($self->docSelected eq $old) {
			$self->docSelect($new)
		}
	}
}


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

sub docSelected {
	my $self = shift;
	$self->{SELECTED} = shift if @_;
	return $self->{SELECTED}
}

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

=item B<docTitle>I<($name)

Strips the path from $name for the title bar.

=cut

sub docTitle {
	my ($self, $name) = @_;
	return basename($name, '');
}

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

sub historyRemove {
	my ($self, $file) = @_;
	croak 'Name not defined' unless defined $file;
	my $h = $self->{HISTORY};
	my ($index) = grep { $h->[$_] eq $file } (0 .. @$h-1);
	splice @$h, $index, 1 if defined $index;
}

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

sub interfaceRemove {
	my ($self, $name) = @_;
	croak 'Name not defined' unless defined $name;

	#remove from document notebook
	my $if = $self->Interface;
	$if->deletePage($name) if defined $if;

	#remove from navigator
	my $navigator = $self->extGet('Navigator');
	$navigator->Delete($name) if defined $navigator;
}

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


=back

=cut

1;




