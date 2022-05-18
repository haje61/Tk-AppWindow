package Tk::AppWindow::BaseClasses::Plugin;

=head1 NAME

Tk::AppWindow::BaseClasses::Plugin - Baseclass for all plugins in this framework

=cut

use strict;
use warnings;
use Carp;
use vars '$AUTOLOAD';

=head1 SYNOPSIS

=over 4

 #This is useless
 my $plug = Tk::AppWindow::BaseClasses::Plugin->new($frame);

 #This is what you should do
 use base(Tk::AppWindow::BaseClasses::Plugin);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$frame should be the first in @_
    ...
    return $self
 }

=back

=head1 DESCRIPTION

Tk::AppWindow::BaseClasses::Plugin is the base object for all plugins in Wx::Perl::FrameWorks. All plugins inherit
this class. It has all the methods needed for the Broadcast/Listen system. It has access to the Wx::Perl::FrameWorks object.
It has the core mechanism in place if your plugins need to reconfigure or veto a close command.

=back

=cut

sub new {
	my ($proto, $window, $args) = (@_);
	my $class = ref($proto) || $proto;
	my $self = {
		APPWINDOW => $window,
		ARGS => $args,
	};
	bless ($self, $class);

	return $self;
}

sub AUTOLOAD {
	my $self = shift;
	return if $AUTOLOAD =~ /::DESTROY$/;
	$AUTOLOAD =~ s/^.*:://;
	return $self->{APPWINDOW}->$AUTOLOAD(@_);
}

=head1 METHODS

=over 4

=cut

sub BalloonAttach {
	my $self = shift;
	my $b = $self->GetPlugin('Balloon');
	$b->Attach(@_) if defined $b;
}

=item B<CanQuit>

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=cut

sub CanQuit { return 1 }

sub CleanUp { delete $_[0]->{ARGS} }

sub ConfVirtEvent {
	my $self = shift;
	while (@_) {
		my $event = shift;
		my $accel = shift;
		$self->eventAdd($event, $accel);
# 		$self->eventAdd($event, $accel) unless defined $self->eventInfo($event);
	}
}

=item B<GetAppWindow>

Returns a reference to the toplevel frame that created it. The toplevel frame should be a Wx::Perl::FrameWorks class.

=cut

sub GetAppWindow { return $_[0]->{APPWINDOW} }

sub GetArgsRef { return $_[0]->{ARGS} }

=item B<MenuItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<MenuBar> plugin. You can return a list
with menu items here. For details on the format see B<Wx::Perl::FrameWorks::Plugins::MenuBar>

=cut

sub MenuItems {
	return ();
}

=item B<Name>

returns the module name of $self, without the path. So, if left uninherited, it returns 'Plugin'.

=cut

sub Name {
	my $self = shift;
	my $name = ref $self;
	$name =~ s/.*:://;
	return $name
}

=item B<ReConfigure>

Does nothing. It is called when the user clicks the Apply button in the settings dialog. Overwrite it to act on 
modified settings.

=cut

sub ReConfigure {}

=item B<Require>

=cut

sub Require {
	my $self = shift;
	my $f = $self->GetAppWindow;
	my $args = $self->GetArgsRef;
	while (@_) {
		my $m = shift;
		unless (defined($f->GetPlugin($m))) {
			$f->LoadPlugin($m, $args);
		}
	}
}

sub StatusItems {
	return ();
}

sub StatusMessage {
	my $self = shift;
	my $sb = $self->GetPlugin('StatusBar');
	$sb->Message(@_) if defined $sb;
}

=item B<ToolItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<ToolBar> plugin. You can return a list
with menu items here. For details on the format see B<Wx::Perl::FrameWorks::Plugins::MenuBar>

=cut

sub ToolItems {
	return ();
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hansjeuken@xs4all.nl)

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
__END__
