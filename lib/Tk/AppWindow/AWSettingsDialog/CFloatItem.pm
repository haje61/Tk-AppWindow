package Tk::AppWindow::AWSettingsDialog::CFloatItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CTextItem);
Construct Tk::Widget 'CFloatItem';

use Scalar::Util::Numeric qw(isfloat isint);

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 if $$var eq '';
	return isint $$var unless isfloat $$var;
	return 1
}

1;
