package Tk::AppWindow::Plugins::Keyboard;

=head1 NAME

Tk::AppWindow::Plugins::FileCommands - a plugin for opening, saving and closing files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->AddPreConfig(
		-keyboardbindings => ['PASSIVE', undef, undef, []],
	);

	$self->{BOUND} = {};
	$self->AddPostConfig('ConfigureBindings', $self);
	return $self;
}

=head1 METHODS

=cut

sub AddBinding {
	my ($self, $command, $key) = @_;
	my $bound = $self->{BOUND};
	my $w = $self->GetAppWindow;
	if (exists $bound->{$command}) {
		warn "Command '$command' is bound to key " . $bound->{$command} . ". Releasing this binding";
		$w->bind("<$key>", '');
	}
	$bound->{$command} = $key;
	$w->bind("<$key>", [$w, 'CommandExecute', $command]);
}


sub ConfigureBindings {
	my $self = shift;
	my $bindings = $self->ConfigGet('-keyboardbindings');
	my @b = @$bindings;
	while (@b) {
		my $command = shift @b;
		my $key = shift @b;
		$self->AddBinding($command, $key);
	}
}

sub ReConfigure {
	my $self = shift;
	my $bound = $self->{BOUND};
	my $w = $self->GetAppWindow;
	for (keys %$bound) {
		my $key = delete $bound->{$_};
		$w->bind("<$key>", '');
	}
	$self->ConfigureBindings
}

1;
