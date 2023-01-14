package Tk::AppWindow::BaseClasses::Extension;

=head1 NAME

Tk::AppWindow::BaseClasses::Extension - Baseclass for all extensions in this framework

=cut

use strict;
use warnings;
use Carp;
use vars '$AUTOLOAD';

=head1 SYNOPSIS

=over 4

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::Extension->new($frame);

 #This is what you should do
 package Tk::AppWindow::Ext::MyExtension
 use base(Tk::AppWindow::BaseClasses::Extension);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=back

=head1 DESCRIPTION

Tk::AppWindow::BaseClasses::Extension is the base object for all extenstions in this Tk::AppWindow framework. All extensions inherit
this class. It has access to the Tk::AppWindow object and autoloads its methods.
It has the core mechanisms in place if your extensions need to reconfigure or veto a close command.

Use this class as a basis to define your own extension.

=back

=cut

sub new {
	my ($proto, $window) = (@_);
	my $class = ref($proto) || $proto;
	my $self = {
		APPWINDOW => $window,
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

=item B<BalloonAttach>I<@options>

=over 4

Calls the Attach method of the Balloon widget if the extens Balloon is loaded

=back

=cut

sub BalloonAttach {
	my $self = shift;
	my $b = $self->GetExt('Balloon');
	$b->Attach(@_) if defined $b;
}

=item B<CanQuit>

=over 4

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=back

=cut

sub CanQuit { return 1 }

=item B<GetAppWindow>

Returns a reference to the MainWindow widget.

=cut

sub GetAppWindow { return $_[0]->{APPWINDOW} }

=item B<MenuItems>

=over 4

Returns an empty list. It is there for you to overwrite. It is called by the B<MenuBar> plugin. You can return a list
with menu items here. For details on the format see L<Tk::AppWindow::Ext::MenuBar>

=back

=cut

sub MenuItems {
	return ();
}

=item B<Name>

=over 4

returns the module name of $self, without the path. So, if left uninherited, it returns 'Extension'.

=back

=cut

sub Name {
	my $self = shift;
	my $name = ref $self;
	$name =~ s/.*:://;
	return $name
}

=item B<ReConfigure>

=over 4

Does nothing. It is called when the user clicks the Apply button in the settings dialog. Overwrite it to act on 
modified settings.

=back

=cut

sub ReConfigure {}

=item B<Require>I<($extension)>

=over 4

Only call this during extension construction.
Loads $extension if it isn't already.

=back

=cut

sub Require {
	my $self = shift;
	my $f = $self->GetAppWindow;
	my $args = $self->GetArgsRef;
	while (@_) {
		my $m = shift;
		unless (defined($f->GetExt($m))) {
			$f->LoadExtension($m, $args);
		}
	}
}

=item B<StatusMessage>I<($text>)>

=over 4

Sends a message to the status bar if it is loaded. See L<Tk::AppWindow::Ext::StatusBar>

=back

=cut

sub StatusMessage {
	my $self = shift;
	my $sb = $self->GetExt('StatusBar');
	$sb->Message(@_) if defined $sb;
}

=item B<ToolItems>

=over 4

Returns and empty list. It is there for you to overwrite. It is called by the B<ToolBar> extension. You can return a list
with menu items here. For details on the format see L<Tk::AppWindow::Ext::ToolBar>

=back

=cut

sub ToolItems {
	return ();
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
__END__
