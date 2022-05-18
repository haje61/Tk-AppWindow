package Tk::AppWindow::AWSettingsDialog::CFontItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CTextItem);
Construct Tk::Widget 'CFontItem';
require Tk::FontDialog;


sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	my @bopt = ();
	if (my $image = $self->Plugin->GetArt('preferences-desktop-font')) {
		push @bopt, -image => $image
	} else {
		push @bopt, -text => 'Select'
	}
	my $but = $self->Button(@bopt,
		-command => sub {
			my $dialog = $self->FontDialog(
				-title => "Select font",
				-initfont => $$var,
			);
			my $font = $dialog->Show(-popover => $self->toplevel);
			if (defined $font) {
				$$var = $font;
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
}

1;
