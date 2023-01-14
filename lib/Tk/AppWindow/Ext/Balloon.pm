package Tk::AppWindow::Ext::Balloon;

=head1 NAME

Tk::AppWindow::Ext::Balloon - Adding ballon functionality

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require Tk::Balloon;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Balloon'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=over 4

Adds a balloon widget to your application

=back

=head1 B<CONFIG VARIABLES>

=over 4

none

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{BALLOON} = $self->GetAppWindow->Balloon;
	return $self;
}

=head1 METHODS

=over 4

=item B<Attach>I<($widget => $message)>

=over 4

Loads a theme index file and returns the information in it in a hash.
It returns a reference to this hash.

=back

=cut

sub Attach {
	my $self = shift;
	$self->{BALLOON}->attach(@_);
}

=item B<Balloon>

=over 4

Returns a reference to the Balloon widget.

=back

=cut

sub Balloon {
	return $_[0]->{BALLOON}
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
