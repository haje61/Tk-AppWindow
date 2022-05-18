package Tk::AppWindow::AWSettingsDialog::CFileItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CTextItem);
Construct Tk::Widget 'CFileItem';

sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	my @opt = ();
	if (my $image = $self->Plugin->GetArt('stock_folder')) {
		push @opt, -image => $image
	} else {
		push @opt, -text => 'Select'
	}
	my $b = $self->Button(@opt,
		-command => sub {
			my $file = $self->getOpenFile(
# 				-initialdir => $initdir,
				-popover => 'mainwindow',
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$self->Advertise(Select => $b);
}
1;
