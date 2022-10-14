package Tk::YAMessageDialog;

use Tk;
use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'YAMessageDialog';

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


1;
