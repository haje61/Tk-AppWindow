package Tk::AppWindow::BaseClasses::Plugin;

=head1 NAME

Tk::AppWindow::BaseClasses::Plugin - Baseclass for all plugins.

=cut

use strict;
use warnings;
use vars '$AUTOLOAD';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

A plugin is different from an extension in a couple of ways:

 - A plugin can be loaded and unloaded by the end user.
   If they do not desire the functionality they can simply 
   unload it.
 - A plugin can not define config variables

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
	$self->after(1, [configureBars => $self]);
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

Returns 1. It is there for you to overwrite. It is called when you attempt to close the window or execute the quit command.
Overwrite it to check for unsaved data and possibly veto these commands by returning a 0.

=cut

sub CanQuit { return 1 }


=item B<GetAppWindow>

Returns a reference to the toplevel frame. The toplevel frame should be a Tk::AppWindow class.

=cut

sub configureBars {
	my $self = shift;
	my $menu = $self->GetExt('MenuBar');
	if (defined $menu) {
		my @items = $self->MenuItems;
		$menu->ReConfigure unless @items eq 0;
	}
	my $tool = $self->GetExt('ToolBar');
	if (defined $tool) {
		my @items = $self->ToolItems;
		$tool->ReConfigure unless @items eq 0;
	}
}

sub GetAppWindow { return $_[0]->{APPWINDOW} }

=item B<MenuItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

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

sub ReConfigure {
	return 1
}

=item B<ToolItems>

Returns and empty list. It is there for you to overwrite. It is called by the B<Plugins> extension. You can return a list
with menu items here. For details on the format see B<Tk::AppWindow::Ext::MenuBar>

=cut

sub ToolItems {
	return ();
}

=item B<UnLoad>

Returns 1. For you to overwrite. Doe here what needs to be done to safely destroy the plugin.

=cut

sub Unload {
	return 1;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
__END__
