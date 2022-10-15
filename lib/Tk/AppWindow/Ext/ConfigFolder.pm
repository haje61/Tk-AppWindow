package Tk::AppWindow::Ext::ConfigFolder;

=head1 NAME

Tk::AppWindow::Plugins::FileCommands - a plugin for opening, saving and closing files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use File::Path qw(make_path);

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=back

=cut
my $configfolder;
if ($^O eq 'MSWin32') {
	$configfolder = $ENV{LOCALAPPDATA} . '/' 
} else {
	$configfolder = $ENV{HOME} . '/.local/'
}

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->ConfigInit(
		-configfolder => ['ConfigFolder', $self, $configfolder . $self->ConfigGet('-appname')],
	);

	return $self;
}

=head1 METHODS

=cut

sub ConfigFolder {
	my $self = shift;
	if (@_) { $self->{CONFIGFOLDER} = shift }
	my $f = $self->{CONFIGFOLDER};
	unless (-e $f) {
		unless (make_path($f)) {
			warn "Could not create path $f";
		}
	}
	return $self->{CONFIGFOLDER}
}

1;
