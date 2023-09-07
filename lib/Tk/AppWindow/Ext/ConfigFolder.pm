package Tk::AppWindow::Ext::ConfigFolder;

=head1 NAME

Tk::AppWindow::Ext::ConfigFolder - save your settings files in a ConfigFolder

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use File::Path qw(make_path);
use Config;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-configfolder>

The default value depends on your operating system.

On Windows: $ENV{LOCALAPPDATA}/appname
Others: $ENV{HOME}/.local/appname

You can overwrite it at launch by setting a folder yourself.

=item Switch: B<-savegeometry>

Default value is 1

If set it will save the applications geometry on exit.
When reloaded the previously saved geometry is restored.
In experimental stage

=back

=cut

my $configfolder;
if ($Config{osname} eq 'MSWin32') {
	$configfolder = $ENV{LOCALAPPDATA} . '\\' 
} else {
	$configfolder = $ENV{HOME} . '/.local/share/'
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->configInit(
		-configfolder => ['ConfigFolder', $self, $configfolder . $self->configGet('-appname')],
	);

	return $self;
}

=head1 METHODS

=over 4

None.

=cut

sub ConfigFolder {
	my $self = shift;
	if (@_) { $self->{CONFIGFOLDER} = shift }
	my $f = $self->{CONFIGFOLDER};
	unless (-e $f) {
		unless (make_path($f)) {
			die "Could not create path $f";
		}
	}
	return $self->{CONFIGFOLDER}
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
