package Tk::AppWindow::Ext::SDI;

=head1 NAME

Tk::AppWindow::Ext::SDI - single document interface

=cut

use strict;
use warnings;

use vars qw($VERSION);
$VERSION="0.01";
use File::Basename;
use File::Spec;
require Tk::YAMessage;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -contentmanagerclass => 'Tk::MyContentHandler',
    -extensions => ['SDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a single document interface to your application.
It is written as a multiple document interface with a maximum of one document.
This makes it easy for L<Tk::AppWindow::Ext::MDI> to inherit SDI.

When L<Tk::AppWindow::Ext::MenuBar> is loaded it creates menu 
entries for creating, opening, saving and closing files. It also
maintaines a history of recentrly closed files.

When L<Tk::AppWindow::Ext::ToolBar> is loaded it creates toolbuttons
for creating, opening, saving and closing files.

You should define a content handler based on the abstract
baseclass L<Tk::AppWindow::BaseClasses::ContentManager>. See also there.

=head1 CONFIG VARIABLES

=over 4

=item B<-contentmanagerclass>

This one should always be specified and you should always define a 
content manager class inheriting L<Tk::AppWindow::BaseClasses::ContentManager>.
This base class is a valid Tk widget.

=item B<-contentmanageroptions>

The possible options to pass on to the contentmanager.
These will also become options to the main application.

=item B<-maxhistory>

Default value is 12.

=item B<-filetypes>

Default value is "All files|*"

=item B<-historymenupath>

Specifies the default location in the main menu of the history menu.
Default value is File::Open recent. See also L<Tk::AppWindow::Ext::MenuBar>.

=item B<-readonly>

Default value 0. 

=back

=head1 COMMANDS

=over 4

=item B<doc_close>

=item B<doc_new>

=item B<doc_open>

=item B<doc_save>

=item B<doc_save_as>

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require( qw[ConfigFolder] );

	my $args = $self->GetArgsRef;
	my $cmo = delete $args->{'-contentmanageroptions'};
	$cmo = [] unless defined $cmo;
	my @preconfig = ();
	for (@$cmo) {
		push @preconfig, $_, ['PASSIVE', undef, undef, '']
	}

	$self->{CURRENT} = undef;
	$self->{DOCS} = {};
	$self->{HISTORY} = [];

	$self->addPreConfig(@preconfig,
		-contentmanagerclass => ['PASSIVE', undef, undef, 'Wx::Perl::FrameWorks::BaseClasses::ContentManager'],
		-contentmanageroptions => ['PASSIVE', undef, undef, $cmo],
		-maxhistory => ['PASSIVE', undef, undef, 12],
		-filetypes => ['PASSIVE', undef, undef, "All files|*"],
		-historymenupath => ['PASSIVE', undef, undef, 'File::Open recent'],
		-readonly => ['PASSIVE', undef, undef, 0],
	);
	$self->cmdConfig(
		doc_new => ['CmdDocNew', $self],
		doc_open => ['CmdDocOpen', $self],
		doc_save => ['CmdDocSave', $self],
		doc_save_as => ['CmdDocSaveAs', $self],
		doc_close => ['CmdDocClose', $self],
		pop_hist_menu => ['CmdPopulateHistoryMenu', $self],
	);

	$self->addPostConfig('LoadHistory', $self);
	return $self;
}

=head1 B<METHODS>

=over 4

=cut

sub CanQuit {
	my $self = shift;
	my $close = 1;
	my @docs = $self->docList;
	for (@docs) {
		my $name = $_;
		my $doc = $self->docGet($name);
		if ($doc->IsModified) {
		#confirm save dialog comes here
			my $q = $self->YAMessage(
				-title => 'Warning, file modified',
				-image => $self->getArt('dialog-warning', 32),
				-buttons => [qw(Yes No Cancel)],
				-text => 
					"Closing " . basename($name) .
					".\nText has been modified. Save it?",
				-defaultbutton => 'Yes',
			);
			my $answer = $q->Show(-popover => $self->GetAppWindow);
			if ($answer eq 'Yes') {
				$self->CmdDocSave($name)
			} elsif ($answer eq 'Cancel') {
				$close = 0
			}
		}
		last if $close eq 0;
	}
	$self->SaveHistory;
	return $close
}


sub ClearCurrent {
	my $self = shift;
	$self->docSelected(undef);
	$self->configPut(-title => $self->configGet('-appname'));
}

=item B<CmdDocClose>

Closes the current document

=cut

sub CmdDocClose {
	my $self =  shift;
	my $doc = $self->docCurrent;
	return 1 unless (defined $doc);
	if ($self->docConfirmSave($self->docSelected)) {
		$self->docClose($self->docSelected);
		my $geosave = $self->geometry;
		$doc->destroy;
		$self->geometry($geosave);
		return 1;
	}
	return 0
}

=item B<CmdDocNew>

Creates a new document. In and SDI environment it closes
the currently existing one first.

=cut

sub CmdDocNew {
	my ($self, $name) = @_;
	$name = $self->docUntitled unless defined $name; 
	my $cm = $self->CreateContentHandler($name);
# 	return 0 unless defined $cm;

	#add to navigator
	my $navigator = $self->extGet('Navigator');
	$navigator->Add($name) if defined $navigator;

	$self->docSelect($name);
	return 1;
}

=item B<CmdDocOpen>I(?$file?);

Creates a new document. In and SDI environment it closes
the currently existing one first.

If $file is not specified it launches a file dialog.

=cut

sub CmdDocOpen {
	my ($self, $file) = @_;
	unless (defined($file)) {
		my @op = ();
		@op = (-popover => 'mainwindow') unless $self->OSName eq 'MSWin32';
		$file = $self->getOpenFile(@op,
# 			-initialdir => $initdir,
# 			-popover => 'mainwindow',
		);
	}
	if ($self->docExists($file)) {
		$self->docSelect($file);
		return 1
	}
	if (defined $file) {
		my $file = File::Spec->rel2abs($file);
		if ($self->CmdDocNew($file)) {
			my $doc = $self->docGet($file);

			#remove from history
			my $h = $self->{HISTORY};
			my ($index) = grep { $h->[$_] eq $file } (0 .. @$h-1);
			splice @$h, $index, 1 if defined $index;

			if ($doc->Load($file)) {
				$self->log("Opened $file");
				return 1
			}
		}
		$self->logWarning("Opening '$file' failed");
	}
 	return 0
}

=item B<CmdDocSave>I(?$file?);

Saves a document.

If $file is not specified it saves the current document.

For a new document it will call I<CmdDocSaveAs>.

=cut

sub CmdDocSave {
	my ($self, $name) = @_;
	return 0 if $self->configGet('-readonly');
	
	my $doc;
	unless (defined $name) {
		$doc = $self->docCurrent;
		$name = $self->{CURRENT};
	} else {
		$doc = $self->docGet($name);
	}

	if (defined $doc) {
		unless ($name =~ /^Untitled/) {
			if ($doc->Save($name)) {
				$self->log("Saved '$name'");
				return 1
			}
		} else {
			return $self->CmdDocSaveAs($name);
		}
	}
	return 1
}

=item B<CmdDocSaveAs>I(?$file?);

Saves a document under a new name. Launches a file dialog.

If $file is not specified it saves the current document.

For a new document it will call I<CmdDocSaveAs>.

=cut

sub CmdDocSaveAs {
	my ($self, $name) = @_;
	return 0 if $self->configGet('-readonly');

	my $doc;
	unless (defined $name) {
		$doc = $self->docCurrent;
		$name = $self->{CURRENT};
	} else {
		$doc = $self->docGet($name);
	}

	if (defined $doc) {
		my @op = ();
		@op = (-popover => 'mainwindow') unless $self->OSName eq 'MSWin32';
		my $file = $self->getSaveFile(@op,
# 			-initialdir => $initdir,
# 			-popover => 'mainwindow',
		);
		if (defined $file) {
			$file = File::Spec->rel2abs($file);
			if ($doc->Save($file)) {
				$self->log("Saved '$file'");
				$self->docRename($name, $file);
				return 1
			} else {
				return 0
			}
		}
	}
	return 1
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

sub CreateContentHandler {
	my ($self, $name) = @_;
	if ($self->CmdDocClose) {
		my $cmclass = $self->configGet('-contentmanagerclass');
		my $h = $self->WorkSpace->$cmclass(-extension => $self)->pack(-expand => 1, -fill => 'both');
		$self->{DOCS}->{$name} = $h;
		$self->update;
		return $h;
	}
	return undef;
}

sub docClose {
	my ($self, $name) = @_;
	my $doc = $self->docGet($name);
	my $filename = $name;

	if ($doc->Close) {
		#Add to history
		if (defined($filename) and (-e $filename)) {
			my $hist = $self->{HISTORY};
			unshift @$hist, $filename;

			#Keep history list below maximum
			my $siz = @$hist;
			pop @$hist if ($siz > $self->configGet('-maxhistory'));
		}

		#delete from document hash
		delete $self->{DOCS}->{$name};

		#delete from navigator
		my $navigator = $self->extGet('Navigator');
		if (defined $navigator) {
			$navigator->Delete($name) if defined $navigator;
		}

		if ((defined $self->docSelected) and ($self->docSelected eq $name)) { 
			$self->ClearCurrent;
		}
		return 1
	}
	return 0
}

sub docConfirmSave {
	my ($self, $name) = @_;
	my $doc = $self->docGet($name);
	if ($doc->IsModified) {
	#confirm save dialog comes here
		my $q = $self->YAMessage(
			-title => 'Warning, file modified',
			-image => $self->getArt('dialog-warning', 32),
			-buttons => [qw(Yes No Cancel)],
			-text => 
				"Closing " . basename($name) .
				".\nDocument has been modified. Save it?",
			-defaultbutton => 'Yes',
		);
		my $answer = $q->Show(-popover => $self->GetAppWindow);
		if ($answer eq 'Yes') {
			unless ($self->CmdDocSave) {
				return 0
			}
		} elsif ($answer eq 'Cancel') {
			return 0
		}
	}
	return 1
}

=item B<docCurrent>

Returns the currently selected document object.

=cut

sub docCurrent {
	my $self = shift;
	my $current = $self->{CURRENT};
	if (defined $current) {
		return $self->{DOCS}->{$current}
	}
	return undef
}

=item B<docExists>I<($name)

Returns 1 if $name exists in the document pool. Else returns 0.

=cut

sub docExists {
	my ($self, $name) = @_;
	return exists $self->{DOCS}->{$name}
}

=item B<docGet>I<($name)

Returns document object for $name.

=cut

sub docGet {
	my ($self, $name) = @_;
	return $self->{DOCS}->{$name}
}

=item B<docList>

Returns a list of all open documents.

=cut

sub docList {
	my $self = shift;
	my $dochash = $self->{DOCS};
	return keys %$dochash;
}

sub docSelect {
	my ($self, $name) = @_;
	$self->SelectDoc($name);
}

sub docSelected {
	my $self = shift;
	if (@_) { $self->{CURRENT} = shift }
	return $self->{CURRENT}
}

=item B<docRename>I<($old, $new)

Renames a loaded document.

=cut

sub docRename {
	my ($self, $old, $new) = @_;

	unless ($old eq $new) {
		my $doc = delete $self->{DOCS}->{$old};
		$self->{DOCS}->{$new} = $doc;

		#rename in navigator
		my $navigator = $self->extGet('Navigator');
		if (defined $navigator) {
			$navigator->Delete($old);
			$navigator->Add($new);
		}

		if ($self->docSelected eq $old) {
			$self->docSelect($new)
		}
	}
}

=item B<docTitle>I<($name)

Strips the path from $name for the title bar.

=cut

sub docTitle {
	my ($self, $name) = @_;
	return basename($name, '');
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

sub LoadHistory {
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

sub MenuItems {
	my $self = shift;
	my $readonly = $self->configGet('-readonly');

	my @items = (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
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

sub SaveHistory {
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

sub SelectDoc {
	my ($self, $name) = @_;
	$self->{CURRENT} = $name;
	$self->configPut(-title => $self->configGet('-appname') . ' - ' . $self->docTitle($name));
	my $navigator = $self->extGet('Navigator');
	$navigator->SelectEntry($name) if defined $navigator;
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

__END__

