package Tk::AppWindow::BaseClasses::Extension;

=head1 NAME

Tk::AppWindow::BaseClasses::Extensions - Baseclass for all extensions in this framework

=cut

use strict;
use warnings;
use Carp;
use vars '$AUTOLOAD';

=head1 SYNOPSIS

=over 4

 #This is useless
 my $plug = Tk::AppWindow::BaseClasses::Exteension->new($frame);

 #This is what you should do
 use base(Tk::AppWindow::BaseClasses::Plugin);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=back

=head1 DESCRIPTION

Tk::AppWindow::BaseClasses::Extension is the base object for all extenstions in Tk::AppWindow framework. All extensions inherit
this class. It has access to the Tk::AppWindow object and autoloads its methods.
It has the core mechanism in place if your extensions need to reconfigure or veto a close command.

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
	my $b = $self->GetExt('Balloon');
	$b->Attach(@_) if defined $b;
}

=item B<CanQuit>

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=cut

sub CanQuit { return 1 }

sub CleanUp { delete $_[0]->{ARGS} }

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
		unless (defined($f->GetExt($m))) {
			$f->LoadExtension($m, $args);
		}
	}
}

sub StatusItems {
	return ();
}

sub StatusMessage {
	my $self = shift;
	my $sb = $self->GetExt('StatusBar');
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
