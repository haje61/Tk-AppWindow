package Tk::YAMessage;

=head1 NAME

Tk::YAMessage - Yet another message box

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Tk;
use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'YAMessage';

=head1 SYNOPSIS

=over 4

 require Tk::YAMessage;
 my $dialog = $window->YAMessage(
	-image = $window->Getimage('info');
	-text => 'Hello',
 );
 $dialog->Show;

=back

=head1 DESCRIPTION

=over 4

Provides a basic message box. Less noisy than Tk::MessageBox.
Inherits L<Tk::YADialog>.

=back

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-image>

=over 4

Default value none.

=back

=item Switch: B<-text>

=over 4

Default value none.

=back

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	unless (exists $args->{'-buttons'}) {
		$args->{'-buttons'} = ['Ok'];
		$args->{'-defaultbutton'} = 'Ok';
	}
	$self->SUPER::Populate($args);
	
	my $i = $self->Label->pack(-side => 'left', -padx => 10, -pady =>10);
	my $t = $self->Label()->pack(-side => 'left', -padx => 10, -pady =>10);
	$self->ConfigSpecs(
		-image => [$i],
		-text => [$t],
		DEFAULT => ['SELF'],
	);
}

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
