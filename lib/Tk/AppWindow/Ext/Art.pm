package Tk::AppWindow::Ext::Art;

=head1 NAME

Tk::AppWindow::Plugins::Art - Use icon libraries quick & easy

=cut


use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

use File::Basename;
use Image::LibRSVG;
use MIME::Base64;
use Tk;
require Tk::Photo;
use Tk::PNG;
use Tk::JPEG;

my @extensions = (
	'.jpg',
	'.jpeg',
	'.png',
	'.gif',
	'.xbm',
	'.xpm',
	'.svg',
);

my %photoext = (
	'.jpg' => ['Photo', -format => 'jpeg'],
	'.jpeg' => ['Photo', -format => 'jpeg'],
	'.png' => ['Photo', -format => 'png'],
);

my @defaulticonpath = ();
if ($^O eq 'MSWin32') {
	push @defaulticonpath, $ENV{ALLUSERSPROFILE} . '\Icons'
} else {
	push @defaulticonpath, $ENV{HOME} . '/.local/share/icons',
	push @defaulticonpath, '/usr/share/icons',
	push @defaulticonpath, '/usr/local/share/icons',
}

my @iconpath = ();

=head1 SYNOPSIS

=over 4

 my $depot = new Wx::Perl::IconDepot(\@pathnames);
 $depot->SetThemes($theme1, $theme2, $theme3);
 my $wxbitmap = $depot->GetBitmap($name, $size, $context)
 my $wxicon = $depot->GetIcon($name, $size, $context)
 my $wximage = $depot->GetImage($name, $size, $context)

=back

=head1 DESCRIPTION

This module allows B<Wx> easy access to icon libraries used in desktops
like KDE and GNOME.

It supports libraries containing scalable vector graphics like Breeze if
B<Image::LibRSVG> is installed. If not you are confined to bitmapped libraries
like Oxygen or Adwaita.

On Windows you have to install icon libraries yourself in C:\ProgramData\Icons.
You will find plenty of them on Github. Extract an icon set and copy the main
folder of the theme (the one that contains the file 'index.theme') to
C:\ProgramData\Icons. On Linux you will probably find some icon themes
in /usr/share/icons.

The constructor takes a reference to a list of folders where it finds the icons
libraries. If you specify nothing, it will assign default values for:

Windows:  $ENV{ALLUSERSPROFILE} . '\Icons'. IconDepot will not create 
the folder if it does not exist.

Others: $ENV{HOME} . '/.local/share/icons', '/usr/share/icons'

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $args = $self->GetArgsRef;

	$self->{THEMEPOOL} = {};
	$self->{THEMES} = {};
	$self->{ICONSIZE} = undef;

	$self->CommandsConfig(
		available_icon_sizes => ['AvailableSizesCurrentTheme', $self],
		available_icon_themes => ['AvailableThemes', $self],
	);

	$self->AddPreConfig(
		-iconsize => ['PASSIVE', 'iconSize', 'IconSize', 16],
		-icontheme => ['PASSIVE', 'iconTheme', 'IconTheme', 'breeze'],
	);

	my $ip = delete $args->{'-iconpath'};
	if (defined $ip) { 
		@iconpath = @$ip 
	} else {
		@iconpath = @defaulticonpath
	}
	$self->CollectThemes(@iconpath);

	return $self;
}


=item B<AvailableContexts>I<($theme, >[ I<$name, $size> ] I<);>

=over 4

Returns a list of available contexts. If you set $name to undef if will return
all contexts of size $size. If you set $size to undef it will return all
contexts associated with icon $name. If you set $name and $size to undef it
will return all known contexts in the theme. out $size it returns a list
of all contexts found in $theme.

=back

=cut

sub AvailableContexts {
	my ($self, $theme, $name, $size) = @_;
	my $t = $self->GetTheme($theme);
	my %found = ();
	if ((not defined $name) and (not defined $size)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((defined $name) and (not defined $size)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				my $ci = $si->{$_};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} elsif ((not defined $name) and (defined $size)) {
		my @names = keys %$t;
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $ci = $t->{$_}->{$size};
				for (keys %$ci) {
					$found{$_} = 1;
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			if (exists $si->{$size}) {
				my $ci = $si->{$size};
				%found = %$ci
			}
		}
	}
	return sort keys %found
}

=item B<AvailableIcons>I<($theme, >[ I<$size, $context> ] I<);>

=over 4

Returns a list of available icons. If you set $size to undef the list will 
contain names it found in all sizes. If you set $context to undef it will return
names it found in all contexts. If you leave out both then
you get a list of all available icons. Watch out, it might be pretty long.

=back

=cut

sub AvailableIcons {
	my ($self, $theme, $size, $context) = @_;
	my $t = $self->GetTheme($theme);

	my @names = keys %$t;
	my @matches = ();
	if ((not defined $size) and (not defined $context)) {
		@matches = @names
	} elsif ((defined $size) and (not defined $context)) {
		for (@names) {
			if (exists $t->{$_}->{$size}) { push @matches, $_ }
		}
	} elsif ((not defined $size) and (defined $context)) {
		for (@names) {
			my $name = $_;
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) { push @matches, $name }
			}
		}
	} else {
		for (@names) {
			if (exists $t->{$_}->{$size}) {
				my $c = $t->{$_}->{$size};
				if (exists $c->{$context}) {
					push @matches, $_
				}
			}
		}
	}
	return sort @matches
}

=item B<AvailableThemes>

=over 4

Returns a list of available themes it found while initiating the module.

=back

=cut

sub AvailableThemes {
	my $self = shift;
	my $k = $self->{THEMES};
	return sort keys %$k
}


=item B<AvailableSizes>I<($theme, >[ I<$name, $context> ] I<);>

=over 4

Returns a list of available contexts. If you leave out $size it returns a list
of all contexts found in $theme.

=back

=cut

sub AvailableSizes {
	my ($self, $theme, $name, $context) = @_;
	my $t = $self->GetTheme($theme);
	return () unless defined $t;

	my %found = ();
	if ((not defined $name) and (not defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $si = $t->{$_};
			my @sizes = keys %$si;
			for (@sizes) {
				$found{$_} = 1
			}
		}
	} elsif ((defined $name) and (not defined $context)) {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			%found = %$si;
		}
	} elsif ((not defined $name) and (defined $context)) {
		my @names = keys %$t;
		for (@names) {
			my $n = $_;
			my $si = $t->{$n};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$n}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	} else {
		if (exists $t->{$name}) {
			my $si = $t->{$name};
			my @sizes = keys %$si;
			for (@sizes) {
				if (exists $t->{$name}->{$_}->{$context}) {
					$found{$_} = 1
				}
			}
		}
	}
	return sort {$a <=> $b} keys %found
}

sub AvailableSizesCurrentTheme {
	my $self = shift;
	return $self->AvailableSizes($self->ConfigGet('-icontheme'));
}

=item B<CollectThemes>

Called during initialization. It scans the folders the constructor receives for
icon libraries. It loads their index files and stores the info.

=over 4

=back

=cut

sub CollectThemes {
	my $self = shift;
	my %themes = ();
	for (@_) {
		my $dir = $_;
		if (opendir DIR, $dir) {
			while (my $entry = readdir(DIR)) {
				my $fullname = "$dir/$entry";
				if (-d $fullname) {
					if (-e "$fullname/index.theme") {
						my $index = $self->LoadThemeFile($fullname);
						my $main = delete $index->{general};
						if (%$index) {
							$themes{$entry} = {
								path => $fullname,
								general => $main,
								folders => $index,
							}
						}
					}
				}
			}
			closedir DIR;
		}
	}
	$self->{THEMES} = \%themes
}

=item B<CreateIndex>I<($themeindex)>

=over 4

Creates a searchable index from a loaded theme index file. Returns a reference
to a hash.

=back

=cut

sub CreateIndex {
	my ($self, $tindex) = @_;
	my %index = ();
	my $base = $tindex->{path};
	my $folders = $tindex->{folders};
	foreach my $dir (keys %$folders) {
		my @raw = <"$base/$dir/*">;
		foreach my $file (@raw) {
			if ($self->IsImageFile($file)) {
				my ($name, $d, $e) = fileparse($file, @extensions);
				unless (exists $index{$name}) {
					$index{$name} = {}
				}
				my $size = $folders->{$dir}->{Size};
				unless (defined $size) {
					$size = 'unknown';
				}
				unless (exists $index{$name}->{$size}) {
					$index{$name}->{$size} = {}
				}
				my $context = $folders->{$dir}->{Context};
				unless (defined $context) {
					$context = 'unknown';
				}
				$index{$name}->{$size}->{$context} = $file;
			}
		}
	}
	return \%index;
}

=item B<FindImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

=over 4

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=back

=cut

sub FindImage {
	my ($self, $name, $size, $context, $resize) = @_;
	my $img = $self->FindRawImage($name, $size, $resize);
	return $img if defined $img;
	return $self->FindLibImage($name, $size, $context, $resize);
}

=item B<FindImageC>I<($sizeindex, $context)>

=over 4

Looks for an icon in $context for a given size index (a portion of a searchable
index). If it can not find it, it looks for another version in all other 
contexts. Returns the first one it finds.

=back

=cut

sub FindImageC {
	my ($self, $si, $context) = @_;
	if (exists $si->{$context}) {
		return $si->{$context}
	} else {
		my @contexts = sort keys %$si;
		if (@contexts) {
			return $si->{$contexts[0]};
		}
	}
	return undef
}

=item B<FindImageS>I<($nameindex, $size, $context, \$resize)>

=over 4

Looks for an icon of $size for a given name index (a portion of a searchable
index). If it can not find it it looks for another version in all other sizes.
In this case it returns the biggest one it finds and sets $resize to 1.

=back

=cut

sub FindImageS {
	my ($self, $nindex, $size, $context, $resize) = @_;
	if (exists $nindex->{$size}) {
		my $file = $self->FindImageC($nindex->{$size}, $context);
		if (defined $file) { return $file }
	} else {
		if (defined $resize) { $$resize = 1 }
		my @sizes = reverse sort keys %$nindex;
		for (@sizes) {
			my $si = $nindex->{$_};
			my $file = $self->FindImageC($si, $context);
			if (defined $file) { return $file }
		}
	}
	return undef
}

=item B<FindLibImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

=over 4

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=back

=cut

sub FindLibImage {
	my ($self, $name, $size, $context, $resize) = @_;
	unless (defined $size) { $size = 'unknown' }
	unless (defined $context) { $context = 'unknown' }
	my $index = $self->GetTheme($self->ConfigGet('-icontheme'));
	if (exists $index->{$name}) {
		return $self->FindImageS($index->{$name}, $size, $context, $resize);
	}
	return undef;
}

=item B<FindRawImage>I<($name, >[ I<$size, $context, \$resize> ] I<);>

=over 4

Returns the filename of an image in the library. Finds the best suitable
version of the image in the library according to $size and $context. If it
eventually returns an image of another size, it sets $resize to 1. This gives
the opportunity to scale the image to the requested icon size. All parameters
except $name are optional.

=back

=cut

sub FindRawImage {
	my ($self, $name, $size) = @_;
	my $path = $self->{RAWPATH};
	for (@$path) {
		my $folder = $_;
		opendir(DIR, $folder);
		my @files = grep(/!$name\.*/, readdir(DIR));
		closedir(DIR);
		for (@files) {
			my $file = "$folder/$_";
			return $file if $self->IsImage($file);
		}
	}
	return undef
}

=item B<GetIcon>I<($name>, [ I<$size, $context, $force> ] I<);>

=over 4

Returns a Wx::Image object. If you do not specify I<$size> or the icon does
not exist in the specified size, it will find the largest possible icon and
scale it to the requested size. I<$force> can be 0 or 1. It is 0 by default.
If you set it to 1 a missing icon image is returned instead of undef when the
icon cannot be found.

=back

=cut

sub GetIcon {
   my ($self, $name, $size, $context) = @_;
   unless (defined $size) { $size = $self->ConfigGet('-iconsize')}
	my $file = $self->FindImage($name, $size, $context);
	if (defined $file) { 
		return $self->LoadImage($file, $size);
	}
	return undef
}

=item B<GetTheme>I<($themename)>

=over 4

Looks for a searchable index of the theme. If it is not yet created it will
be created first and stored in the index pool.

=back

=cut

sub GetTheme {
	my ($self, $theme) = @_;
	my $pool = $self->{THEMEPOOL};
	if (exists $pool->{$theme}) {
		return $pool->{$theme}
	} else {
		my $themindex = $self->{THEMES}->{$theme};
		if (defined $themindex) {
			my $index = $self->CreateIndex($themindex);
			$pool->{$theme} = $index;
			return $index
		} else {
			warn "Accessing theme '$theme' failed";
			return undef
		}
	}
}

=item B<GetThemePath>I<($theme)>

=over 4

Returns the full path to the folder containing I<$theme>

=back

=cut

sub GetThemePath {
	my ($self, $theme) = @_;
	my $t = $self->{THEMES};
	if (exists $t->{$theme}) {
		return $t->{$theme}->{path}
	} else {
		warn "Icon theme $theme not found"
	}
}

sub IconSize {
	my $self = shift;
	if (@_) { $self->{ICONSIZE} = shift }
	return $self->{ICONSIZE}
}

=item B<IsImageFile>I<($file)>

=over 4

Returns true if I<$file> is an image. Otherwise returns false.

=back

=cut

sub IsImageFile {
	my ($self, $file) = @_;
	unless (-f $file) { return 0 } #It must be a file
	my ($d, $f, $e) = fileparse(lc($file), @extensions);
	if ($e ne '') { return 1 }
	return 0
}

=item B<LoadImage>I<($file)>

=over 4

Loads image I<$file> and returns it as a Wx::Image object.

=back

=cut

sub LoadImage {
	my ($self, $file, $size) = @_;
	if (-e $file) {
		my ($name,$path,$suffix) = fileparse(lc($file), @extensions);
		if (exists $photoext{$suffix}) {
			my $img = $self->GetAppWindow->Photo(
				-file => $file,
				-height => $size,
				-width => $size,
			);
			if (defined $img) {
				return $img
			}
		} elsif ($suffix eq '.svg') {
			my $renderer = Image::LibRSVG->new;
			$renderer->loadFromFileAtSize($file, $size, $size);
			my $png = $renderer->getImageBitmap("png", 100);
			my $img = $self->GetAppWindow->Photo(
				-data => encode_base64($png), 
				-format => 'png'
			);
			if (defined $img) {
				return $img
			}
		} else {
			warn "could not define image type for file $file"
		}
	}  else {
		warn "image file $file not found \n";
	}
	return undef
}

=item B<LoadThemeFile>I<($file)>

=over 4

Loads a theme index file and returns the information in it in a hash.
It returns a reference to this hash.

=back

=cut

sub LoadThemeFile {
	my ($self, $file) = @_;
	$file = "$file/index.theme";
	if (open(OFILE, "<", $file)) {
		my %index = ();
		my $section;
		my %inf = ();
		my $firstline = <OFILE>;
		unless ($firstline =~ /^\[.+\]$/) {
			warn "Illegal file format $file";
		} else {
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ /^\[([^\]]+)\]/) { #new section
					if (defined $section) { 
						$index{$section} = { %inf }
					} else {
						$index{general} = { %inf }
					}
					$section = $1;
					%inf = ();
				} elsif ($line =~ s/^([^=]+)=//) { #new key
					$inf{$1} = $line;
				}
			}
			if (defined $section) { 
				$index{$section} = { %inf } 
			}
			close OFILE;
		}
		return \%index;
	} else {
		warn "Cannot open theme index file: $file"
	}
}

1;
