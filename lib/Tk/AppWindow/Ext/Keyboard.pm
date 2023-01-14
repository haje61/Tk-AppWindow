package Tk::AppWindow::Ext::Keyboard;

=head1 NAME

Tk::AppWindow::Ext::Keyboard - adding easy keyboard bindings

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

=over 4

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Keyboard'],
 );
 $app->MainLoop;

=back

=head1 DESCRIPTION

=cut

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-keyboardboardbindings>

=over 4

Default value is an empty list

Specify a paired list of keyboard bindings.


=back

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

=back

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
