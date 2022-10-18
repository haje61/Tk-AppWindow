package Tk::AppWindow::Ext::SDI;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION="0.01";
use File::Basename;
require Tk::YAMessage;

use base qw( Tk::AppWindow::BaseClasses::Extension );


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

	$self->{CURDOC} = undef;
	$self->{HISTORY} = [];

	$self->AddPreConfig(@preconfig,
		-contentmanagerclass => ['PASSIVE', undef, undef, 'Wx::Perl::FrameWorks::BaseClasses::ContentManager'],
		-contentmanageroptions => ['PASSIVE', undef, undef, $cmo],
		-maxhistory => ['PASSIVE', undef, undef, 12],
		-filetypes => ['PASSIVE', undef, undef, "All files|*"],
		-historymenupath => ['PASSIVE', undef, undef, 'File::Open recent'],
		-readonly => ['PASSIVE', undef, undef, 0],
	);
	$self->CommandsConfig(
		file_new => ['CmdFileNew', $self],
		file_open => ['CmdFileOpen', $self],
		file_save => ['CmdFileSave', $self],
		file_save_as => ['CmdFileSaveAs', $self],
		file_close => ['CmdFileClose', $self],
		pop_hist_menu => ['CmdPopulateHistoryMenu', $self],
	);

	$self->AddPostConfig('LoadHistory', $self);
	return $self;
}

sub CanQuit {
	my $self = shift;
	if ($self->CmdFileClose) {
		$self->SaveHistory;
		return 1;
	}
	return 0
}

sub CurDoc {
	my $self = shift;
	if (@_) { $self->{CURDOC} = shift }
	return $self->{CURDOC}
}

sub CmdFileClose {
	my $self = shift;
	my $close = 1;
	my $doc = $self->{CURDOC};
	return 1 unless (defined $doc);
	my $w = $self->GetAppWindow;
	if ($doc->IsModified) {
	#confirm save dialog comes here
		my $q = $w->YAMessage(
			-title => 'Warning, file modified',
			-image => $self->GetArt('dialog-warning', 32),
			-buttons => [qw(Yes No Cancel)],
			-text => 
				"Closing " . $doc->cget('-filename') .
				".\nText has been modified. Save it?",
			-defaultbutton => 'Yes',
		);
		my $answer = $q->Show(-popover => $w);
		if ($answer eq 'Yes') {
			unless ($self->CmdFileSave) {
				return 0
			}
		} elsif ($answer eq 'Cancel') {
			return 0
		}
	}
	my $name = $doc->cget('-filename');

	if ($doc->Close) {

		$self->ConfigPut('-title', $self->ConfigGet('-appname'));
		#Add to history
		if (defined($name) and (-e $name)) {
			my $hist = $self->{HISTORY};
			unshift @$hist, $name;

			#Keep history list below maximum
			my $siz = @$hist;
			pop @$hist if ($siz > $self->ConfigGet('-maxhistory'));
		}

		$doc->destroy;
		$self->CurDoc(undef);
		$self->update;
		return 1;
	}
	return 0
}

sub CmdFileNew {
	my $self = shift;
	if ($self->CmdFileClose) {
		my $cm = $self->CreateContentHandler->pack(-expand => 1, -fill => 'both');
		$self->CurDoc($cm);
		$self->update;
		return 1
	}
	return 0
}

sub CmdFileOpen {
	my ($self, $file) = @_;
	unless (defined($file)) {
		$file = $self->getOpenFile(
# 			-initialdir => $initdir,
			-popover => 'mainwindow',
		);
	}
	if (defined $file) {
		if ($self->CmdFileNew) {
			my $doc = $self->CurDoc;
			$doc->configure(-filename, $file);

			#remove from history
			my $h = $self->{HISTORY};
			my ($index) = grep { $h->[$_] eq $file } (0 .. @$h-1);
			if (defined $index) {
				splice @$h, $index, 1
			}

			if ($doc->Load) {
				$self->ConfigPut(-title => $self->ConfigGet('-appname') . ' - ' . basename ($file, ''));
				return 1
			}
		}
	}
 	return 0
}

sub CmdFileSave {
	my $self = shift;
	return 0 if $self->ConfigGet('-readonly');
	my $doc = $self->CurDoc;
	if (defined $doc) {
		my $name = $doc->cget('-filename');
		if ($name ne '' ) {
			return $doc->Save
		} else {
			return $self->CmdFileSaveAs;
		}
	}
	return 1
}

sub CmdFileSaveAs {
	my ($self, $file) = @_;
	return 0 if $self->ConfigGet('-readonly');
	my $doc = $self->CurDoc;
	if (defined $doc) {
		my $file = $self->getSaveFile(
	# 		-initialdir => $initdir,
			-popover => 'mainwindow',
		);
		if ($file ne '') {
			$doc->configure(-filename => $file);
			return $doc->Save                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
		}
	}
	return 1
}

sub CmdPopulateHistoryMenu {
	my $self = shift;
	my $mnu = $self->GetExt('MenuBar');
	if (defined $mnu) {
		my $path = $self->ConfigGet('-historymenupath');
		my ($menu, $index) = $mnu->FindMenuEntry($path);
		if (defined($menu)) {
			my $submenu = $menu->entrycget($index, '-menu');
			$submenu->delete(1, 'last');
			my $h = $self->{HISTORY};
			for (@$h) {
				my $f = $_;
				$submenu->add('command',
					-label => $f,
					-command => sub { $self->CmdFileOpen($f) }
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
	my $self = shift;
	my $cmclass = $self->ConfigGet('-contentmanagerclass');
	my $h = $self->WorkSpace->$cmclass(-plugin => $self);
# 	$h->ConfigureCM;
	return $h
}

sub LoadHistory {
	my $self = shift;
	my $folder = $self->ConfigGet('-configfolder');
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
	my @items = (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,			"~File" 	], 
		[	'menu_normal',		'File::',		"~New",					'file_new',				'document-new',	'Control-n'			], 
		[	'menu_separator',	'File::', 		'f1'], 
		[	'menu_normal',		'File::',		"~Open",					'file_open',			'document-open',	'Control-o'			], 
 		[	'menu', 				'File::',		"Open ~recent", 		'pop_hist_menu', 	],
	);
	push @items,
		[	'menu_separator',	'File::', 		'f2' ], 
		[	'menu_normal',		'File::',		"~Save",					'file_save',			'document-save',	'Control-s'			], 
		[	'menu_normal',		'File::',		"~Save as",				'file_save_as',		'document-save-as',],
	unless $self->ConfigGet('-readonly');
	push @items,
		[	'menu_separator',	'File::', 		'f3' ], 
		[	'menu_normal',		'File::',		"~Close",				'file_close',			'document-close',	'Control-O'	], 
	;
	return @items
}

sub ReConfigure {
	my $self = shift;
	print "reconfigure called\n";
	my $doc = $self->CurDoc;
	$doc->ConfigureCM if defined $doc;
}

sub SaveHistory {
	my $self = shift;
	my $hist = $self->{HISTORY};
	if (@$hist) {
		my $folder = $self->ConfigGet('-configfolder');
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

sub ToolItems {
	my $self = shift;
	my @items = (
		#	 type					label			cmd					icon					help		
		[	'tool_button',		'New',		'file_new',			'document-new',	'Create a new document'], 
		[	'tool_button',		'Open',		'file_open',		'document-open',	'Open a document'], 
	);
	push @items,
		[	'tool_button',		'Save',		'file_save',		'document-save',	'Save current document'], 
		[	'tool_button',		'Close',		'file_close',		'document-close',	'Close current document'], 
	unless $self->ConfigGet('-readonly');
	return @items
}

1;

__END__

