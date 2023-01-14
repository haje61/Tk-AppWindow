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

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ConfigFolder'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-configfolder>

=over 4

The default value depends on your operating system.

On Windows: $ENV{LOCALAPPDATA}/appname
Others: $ENV{HOME}/.local/appname

You can overwrite it at launch by setting a folder yourself.

=back

=item Switch: B<-savegeometry>

=over 4

Default value is 1

If set it will save the applications geometry on exit.
When reloaded the previously saved geometry is restored.
In experimental stage

=back

=back

=cut

my $configfolder;
if ($Config{osname} eq 'MSWin32') {
	$configfolder = $ENV{LOCALAPPDATA} . '/' 
} else {
	$configfolder = $ENV{HOME} . '/.local/'
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->AddPreConfig(
		-savegeometry => ['PASSIVE', undef, undef, 1],
	);

	$self->ConfigInit(
		-configfolder => ['ConfigFolder', $self, $configfolder . $self->ConfigGet('-appname')],
	);

	$self->AddPostConfig('PostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

None.

=cut

sub CanQuit {
	my $self = shift;
	if ($self->ConfigGet('-savegeometry')) {
		my $file = $self->ConfigGet('-configfolder') . '/geometry';
		if (open(OFILE, ">", $file)) {
			print OFILE $self->geometry . "\n";
			close OFILE
		}
	}
	return 1
}

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

sub PostConfig {
	my $self = shift;
	if ($self->ConfigGet('-savegeometry')) {
		my $file = $self->ConfigGet('-configfolder') . '/geometry';
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

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

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
