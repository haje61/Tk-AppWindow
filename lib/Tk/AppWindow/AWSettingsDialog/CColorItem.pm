package Tk::AppWindow::AWSettingsDialog::CColorItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWSettingsDialog::CBooleanItem);
Construct Tk::Widget 'CColorItem';
require Tk::AppWindow::AWColorDialog;

# sub Populate {
# 	my ($self,$args) = @_;
# 	$self->SUPER::Populate($args);
# 	$self->ConfigSpecs(
# 		-background => ['SELF', 'DESCENDANTS'],
# 		DEFAULT => ['SELF'],
# 	);
# }
# 
sub CreateHandler {
	my ($self, $var) = @_;
	my $entry = $self->Entry(
		-textvariable => $var,
		-width => 8,
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Entry => $entry);
	my $colorview = $self->Label(
		-width => 8,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'both');
	$self->Advertise(ColorView => $colorview);

	my @bopt = ();
	if (my $image = $self->Plugin->GetArt('preferences-desktop-color')) {
		push @bopt, -image => $image
	} else {
		push @bopt, -text => 'Select'
	}
	my $but = $self->Button(@bopt,
		-command => sub {
			my $dialog = $self->AWColorDialog(
				-title => "Select color",
				-initialcolor => $self->Get,
			);
			my $answer = $dialog->Show(-popover => $self->toplevel);
			if ($answer eq 'Select') {
				$$var = $dialog->Get;
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
}

sub EntryUpdate {
	my $self = shift;
	if ($self->Validate) {
		my $var = $self->cget('-variable');
		$self->Subwidget('ColorView')->configure(-background => $$var);
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('ColorView')->configure(-background => $self->cget('-background'));
		$self->Subwidget('Entry')->configure(-foreground => $self->Plugin->ConfigGet('-errorcolor'));
	}
}

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 unless defined $var;
	return 1 if $$var eq '';
	return $$var =~ /^#(?:[0-9a-fA-F]{3}){1,4}$/
}

1;
