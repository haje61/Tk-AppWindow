package Tk::DocumentTree;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use base qw(Tk::Derived Tk::Frame);

use File::Basename;
use Tk;
use Config;
require Tk::Tree;
#use File::MimeInfo::Magic;

Construct Tk::Widget 'DocumentTree';

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);

	my $sep = '/';
	$sep = '\\' if $Config{osname} eq 'MSWin32';
	$args->{'-scrollbars'} = 'osoe';
	$args->{'-itemtype'} = 'imagetext';
	$args->{'-browsecmd'} = ['EntryClick', $self];
	$args->{'-separator'} = $sep;
	$args->{'-selectmode'} = 'single';
	$args->{'-exportselection'} = 0;

	my $topbar = $self->CreatePathBar;
	$self->Advertise(PATH => $topbar);
	my $tree = $self->Scrolled('Tree',
	)->pack(
		-padx => 2, 
		-pady => 2,
		-expand => 1, 
		-fill => 'both',
	);

	$self->ConfigSpecs(
		-basedir => ['PASSIVE', undef, undef, '.'],
		-diriconcall => ['CALLBACK', undef, undef, ['DefaultDirIcon', $self]],
		-fileiconcall => ['CALLBACK', undef, undef, ['DefaultFileIcon', $self]],
		-entryselect => ['CALLBACK', undef, undef, sub {}],
# 		-background => ['SELF', 'DESCENDANTS'],
# 		-foreground => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$tree],
	);
	$self->Delegates(
		'DEFAULT' => $tree,
	);
}

sub Add {
	my ($self, $new, $type) = @_;

	if ($type eq 'untracked') {
		my @peers = $self->infoChildren('');
		my @op = (-image => $self->GetFileIcon($new));
		for (@peers) {
			if ($self->IsDir($_)) {
				push @op, -before => $_;
				last;
			} elsif ($self->IsFile($_)) {
				push @op, -before => $_;
				last;
			} elsif ($new lt $_) {
				push @op, -before => $_;
				last;
			}
		}
		$self->add($new, @op,
			-text => $new,
			-data => $type,
		);
	} else {
		my $sep = $self->cget('-separator');

		my $name = '';
		my @path = ($new);
		@path = split /$sep/, $new if $new =~ /$sep/;

		while (@path) {
			my $title = shift @path;
			my $data = 'file';
			$data = 'dir' if @path;
			if ($name eq '') {
				$name = $title;
			} else {
				$name = $name . $sep . $title;
			}
			unless ($self->infoExists($name)) {
				my @op = (
					-data => $data,
				);
				my @peers = $self->GetPeers($name);
				
				#We want a sorted list, directories first
				if ($data eq 'dir') {
					for (@peers) {
						my $peer = $_;
						if ($self->IsUntracked($peer)) { #ignore untracked entries
						} elsif ($self->IsFile($peer)) { #we arrived at the end of the directory section
							push @op, -before => $peer;
							last;
						} elsif ($name lt $peer) {
							push @op, -before => $peer;
							last;
						}
					}
					push @op, -image => $self->GetDirIcon($self->GetFileName($name));
				} else {
					for (@peers) {
						my $peer = $_;
						if ($self->IsDir($peer) or $self->IsUntracked($peer)) { #weed through the untracked and ddirectory section of the list
						} elsif ($name lt $peer) {
							push @op, -before => $peer;
							last;
						}
					}
					push @op, -image => $self->GetFileIcon($self->GetFileName($name));
				}
				$self->add($name, @op,
					-text => $title,
					-data => $data,
				);
				$self->autosetmode;
			}
		}
	}
}

sub CreatePathBar {
	return $_[0]->Label(
		-anchor => 'w',
	)->pack(
		-fill => 'x',
		-padx => 2,
		-pady => 2,
	)
}

sub DefaultDirIcon {
	return $_[0]->Pixmap(-file => Tk->findINC('folder.xpm'))
}

sub DefaultFileIcon {
	return $_[0]->Pixmap(-file => Tk->findINC('file.xpm'))
}

sub Delete {
	my ($self, $entry) = @_;
	my $par = $self->GetParent($entry);
	$self->deleteEntry($entry);
	if ($par ne '') {
		my @peers = $self->infoChildren($par);
		$self->Delete($par) unless @peers;
	}
}

sub EntryAdd {
	my ($self, $new) = @_;

	if (-d $new) {
		warn "You can not add a directory\n";
		return
	}
	my $untracked = not -e $new;

	my $type = 'file';
	if ($untracked) {
		$type = 'untracked';
	} else {
		my $sep = $self->cget('-separator');
		$new =~ s/^$sep// unless $Config{osname} eq 'MSWin32';
		my $compath = $self->GetCommonPath($new);
		$new =~ s/^$compath$sep//
	}

	$self->Add($new, $type);
}

sub EntryClick {
	my ($self, $entry) = @_;
	return if $self->IsDir($entry);
	$entry = $self->GetFileName($entry) unless $self->IsUntracked($entry);
	$self->Callback('-entryselect', $entry);
}

sub EntryDelete {
	my ($self, $entry) = @_;
	my $sep = $self->cget('-separator');
	$entry =~ s/^$sep// unless $Config{osname} eq 'MSWin32';
	$entry = $self->StripPath($entry);

	if ($self->IsDir($entry)) {
		warn "You cannot delete a directory: $entry";
		return
	}

	$self->Delete($entry);
	my @c = $self->infoChildren('');
	if (@c) {
		$self->GetCommonPath
	} else {
		$self->SetPath('');
	}
}

sub EntrySelect {
	my ($self, $entry) = @_;

	my $sep = $self->cget('-separator');
	$entry =~ s/^$sep// unless $Config{osname} eq 'MSWin32';
	$entry = $self->StripPath($entry);
	$self->selectionClear;
	$self->anchorClear;
	$self->selectionSet($entry);
}

sub FileList {
	my $self = shift;
	my @list = $self->ItemList;
	my @out = ();
	for (@list) {
		push @out, $self->GetFileName($_);
	}
}

sub GetCommonPath {
	my ($self, $new) = @_;
	my $sep = $self->cget('-separator');

	my @items = $self->ItemList;
	my @files = ();
	while (@items) {
		my $item = shift @items;
		push @files, $self->GetFullPath($item);
	}
	
	my @xfiles = @files;
	push @xfiles, $new if defined $new;

	my @ifiles = ();
	for (@xfiles) {
		my $file = $_;
		$file = $self->GetParent($file);
		my @p = split /$sep/, $file;
		push @ifiles, \@p;
	}

	my $newpath = '';
	if (@ifiles) {
		my $level = 0;
		while ($level >= 0) {
			my $equal = 1;
			my $value = $ifiles[0]->[$level];
			unless (defined $value) {
				$equal = 0;
				$level = -1;
			} else {
				for (0 .. @ifiles - 1) {
					if (defined $ifiles[$_]->[$level]) {
						unless ($ifiles[$_]->[$level] eq $value) {
							$equal = 0;
							last;
						}
					} else {
						$equal = 0;
						last;
					}
				}
				if ($equal) {
					if ($newpath eq '') {
						$newpath = $value
					} else {
						$newpath = $newpath . $self->cget('-separator') . $value;
					}
					$level ++;
				} else {
					$level = -1;
				}
			}
		}
	}

	my $oldpath = $self->GetPath;
	if ($newpath ne $oldpath) {
		$self->SetPath($newpath);
		my @untrack = $self->UntrackedList;
		$self->deleteAll;
		for (@untrack) {
			$self->Add($_, 'untracked');
		}
		for (@files) {
			my $item = $_;
			$item =~ s/^$newpath$sep// unless $newpath eq '';
			$self->Add($item);
		}
	}
	return $newpath
}

sub GetDirIcon {
	my ($self, $name) = @_;
	return $self->Callback('-diriconcall', $name);
}

sub GetFileIcon {
	my ($self, $name) = @_;
	return $self->Callback('-fileiconcall', $name);
}

sub GetFileName {
	my ($self, $item) = @_;
	$item = $self->GetFullPath($item);
	unless ($Config{osname} eq 'MSWin32') {
		$item = $self->cget('-separator') . $item; #unless ($Config{osname} eq 'MSWin32');
	}
	return $item;
}

sub GetFullPath {
	my ($self, $name) = @_;
	my $commonpath = $self->GetPath;
	my $sep = $self->cget('-separator');
	$name = $commonpath . $sep . $name if $commonpath ne'';
	return $name;
}

sub GetParent {
	my ($self, $name) = @_;
	my $dir = dirname($name);
	$dir = '' if $dir eq '.';
	return $dir
}

sub GetPath {
	my $self = shift;
	my $path = $self->Subwidget('PATH')->cget('-text');
	my $sep = $self->cget('-separator');
	$path =~ s/^$sep//;
	return $path;
}

sub GetPeers {
	my ($self, $name) = @_;
	return $self->infoChildren($self->GetParent($name))
}

sub IsDir {
	my ($self, $item) = @_;
	return 1 if $self->infoData($item) eq 'dir';
	return 0;
}

sub IsFile {
	my ($self, $item) = @_;
	return 1 if $self->infoData($item) eq 'file';
	return 0;
}

sub IsUntracked {
	my ($self, $item) = @_;
	return 1 if $self->infoData($item) eq 'untracked';
	return 0;
}

sub ItemList {
	my ($self, $path, $list) = @_;
	$list = [] unless defined $list;
	$path = '' unless defined $path;
	my @children = $self->infoChildren($path);
	for (@children) {
		if ($self->IsUntracked($_)) { #ignoring untracked
		} elsif ($self->IsDir($_)) {
			$self->ItemList($_, $list)
		} else {
			push @$list, $_
		}
	}
	return @$list;
}

sub PathCompare {
	my ($self, $path1, $path2) = @_;
	my @l1 = $self->PathList($path1);
	my @l2 = $self->PathList($path2);
	my $size1 = @l1;
	my $size2 = @l2;
	if ($size1 > $size2) {
		return 1
	} elsif ($size1 eq $size2) {
		return 0
	} else {
		return -1
	}
}

sub PathList {
	my ($self, $path) = @_;
	my $sep = $self->cget('-separator');
	return split /$sep/, $path
}

sub SetPath {
	my ($self, $path) = @_;
	$path = $self->cget('-separator') . $path unless ($Config{osname} eq 'MSWin32');
	$self->Subwidget('PATH')->configure(-text => $path);
}

sub StripPath {
	my ($self, $name) = @_;
	my $path = $self->GetPath;
	my $sep = $self->cget('-separator');
	$name =~ s/^$path$sep// if $path ne '';
	return $name;
}

sub UntrackedList {
	my $self = shift;
	my @top = $self->infoChildren('');
	my @untracked = ();
	for (@top) {
		push @untracked, $_ if $self->infoData($_) eq 'untracked'
	}
	return @untracked
}

1;
