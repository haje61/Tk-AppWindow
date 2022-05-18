package Tk::AppWindow::AWSettingsDialog::CFolderItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CFileItem);
Construct Tk::Widget 'CFolderItem';

sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	$self->Subwidget('Select')->configure(
		-command => sub {
			my $file = $self->chooseDirectory(
# 				-initialdir => $initdir,
				-popover => 'mainwindow',
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	);
}

1;
