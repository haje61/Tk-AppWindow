package Tk::AppWindow::AWSettingsDialog::CBooleanItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'CBooleanItem';

sub Populate {
	my ($self,$args) = @_;

	my $plugin = delete $args->{'-plugin'};
	$self->{PLUGIN} = $plugin;

	$self->SUPER::Populate($args);
	my $var = 0;
	$self->CreateHandler(\$var);

	$self->ConfigSpecs(
		-variable => ['PASSIVE', undef, undef, \$var],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	$self->Checkbutton(
		-onvalue => 1,
		-offvalue => 0,
		-variable => $var,
	)->pack(-side => 'left', -padx => 2);
}

sub EntryUpdate {
}

sub Get {
	my $self = shift;
	my $var = $self->cget('-variable');
	return $$var;
}

sub Plugin {
	return $_[0]->{PLUGIN}
}

sub Put {
	my ($self, $value) = @_;
	my $var = $self->cget('-variable');
	$$var = $value;
}

sub Validate {
	return 1
}

1;
