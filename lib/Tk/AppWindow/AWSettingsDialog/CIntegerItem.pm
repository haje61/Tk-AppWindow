package Tk::AppWindow::AWSettingsDialogs::CIntegerItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CTextItem);
Construct Tk::Widget 'CIntegerItem';

use Scalar::Util::Numeric qw(isint);

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 if $$var eq '';
	return isint $$var
}


1;
