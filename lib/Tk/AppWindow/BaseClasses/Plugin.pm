package Tk::AppWindow::BaseClasses::Plugin;

=head1 NAME

Tk::AppWindow::BaseClasses::Plugin - Baseclass for all plugins.

=cut

use strict;
use warnings;
use vars '$AUTOLOAD';

=head1 SYNOPSIS

=over 4

 #This is useless
 my $plug = Tk::AppWindow::BaseClasses::Plugin->new($frame);

 #This is what you should do
 package Tk::AppWindow::Plugins::MyPlugin
 use base(Tk::AppWindow::BaseClasses::Plugin);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=back

=head1 DESCRIPTION

A plugin is different from an extension in a couple of ways:
 - A plugin can be loaded and unloaded by the end user.
   If they do not desire the functionality they can simply 
   unload it.
 - A plugin can not define config variables

=back

=cut

sub new {
	my ($proto, $window, @required) = (@_);
	my $class = ref($proto) || $proto;
	my $self = {
		APPWINDOW => $window,
	};
	bless ($self, $class);
	for (@required) {
		return undef unless defined $self->GetExt($_);
	}
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

=item B<CanQuit>

=over 4

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=back

=cut

sub CanQuit { return 1 }


=item B<GetAppWindow>

=over 4

Returns a reference to the toplevel frame. The toplevel frame should be a Tk::AppWindow class.

=back

=cut

sub GetAppWindow { return $_[0]->{APPWINDOW} }

=item B<MenuItems>

=over 4

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

=back

=cut

sub MenuItems {
	return ();
}

=item B<Name>

=over 4

returns the module name of $self, without the path. So, if left uninherited, it returns 'Plugin'.

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

sub ReConfigure {
	return 1
}

=item B<ToolItems>

=over 4

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

=back

=cut

sub ToolItems {
	return ();
}

=item B<UnLoad>

=over 4

Returns 1. For you to overwrite. Doe here what needs to be done to safely destroy the plugin.

=back

=cut

sub UnLoad {
	return 1;
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
