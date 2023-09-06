package Tk::AppWindow::Ext::WebBrowser;

=head1 NAME

Tk::AppWindow::Ext::WebBrowser - Open url's in your browser

=cut

use strict;
use warnings;
use Env::Browser qw(run);
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['WebBrowser'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Open url's in your browser

=head1 CONFIG VARIABLES

=over 4

none

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->Require( qw[ConfigFolder] );
	$self->addPreConfig(
		-webbrowser => ['PASSIVE', undef, undef, ''],
	);

	$self->cmdConfig(
		browser_open => ['browserOpenURL', $self],
	);
	return $self;
}

=head1 METHODS

=cut

sub browserDialog {
	my $self = shift;
	my $browser = $self->popEntry("Web browser query", "Your web browser command");
	if ((defined $browser) and ($self->browserInstalled($browser))) {
		$ENV{BROWSER} = $browser;
		$self->configPut(-webbrowser => $browser);
		my $file = $self->configGet('-configfolder') . '/webbrowser';
		if (open(OFILE, ">", $file)) {
			print OFILE $browser . "\n";
			close OFILE;
		}
	}
}

sub browserInstalled {
	my ($self, $browser) = @_;
	my $path = $ENV{PATH};
	return if $browser eq '';
	my @pth = split /\:/, $path;
	my $found = 0;
	for (@pth) {
		my $f = "$_/$browser";
		if (-e $f) {
			$found = 1;
			last;
		}
	}
	$self->popMessage("Browser '$browser' not found", 'dialog-warning') unless $found;
	return $found
}

sub browserOpenURL {
	my ($self, $url) = @_;
	my $file = $self->configGet('-configfolder') . '/webbrowser';
	if (exists $ENV{BROWSER}) {#do nothing
	} elsif ($self->configGet('-webbrowser') ne '') {#set browser from config
		$ENV{BROWSER} = $self->configGet('-webbrowser');
	} elsif (-e $file) {#set browser from file
		if (open(OFILE, "<", "$file")) {
			my $b = <OFILE>;
			close OFILE;
			chomp $b;
			$ENV{BROWSER} = $b;
			$self->configPut(-webbrowser => $b);
		}
	} else {#ask for your favorite browser
		$self->browserDialog
	}
	run($url) if exists $ENV{BROWSER};
}

sub browserReset {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/webbrowser';
	unlink $file if -e $file;
	delete $ENV{BROWSER};
	$self->configPut(-webbrowser => undef);
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
