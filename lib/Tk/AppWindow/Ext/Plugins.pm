package Tk::AppWindow::Ext::Plugins;

=head1 NAME

Tk::AppWindow::Ext::Plugins - load and unload plugins

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Plugins'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{PLUGINS} = {};

	$self->AddPreConfig(
		-plugins => ['PASSIVE', undef, undef, []],
	);

	$self->AddPostConfig('DoPostConfig', $self);
	return $self;
}

=head1 METHODS

=cut

sub CanQuit {
	my $self = shift;
	my @plugs = $self->plugList;
	my $close = 1;
	for (@plugs) {
		$close = 0 unless $self->plugGet($_)->CanQuit
	}
	return $close
}

sub DoPostConfig {
	my $self = shift;
	my $plugins = $self->configGet('-plugins');
	for (@$plugins) {
		$self->plugLoad($_);
	}
}

sub MenuItems {
	my $self = shift;
	my @items = ();
	my @l = $self->plugList;
	for (@l) {
		push @items, $self->plugGet($_)->MenuItems
	}
	return @items;
}

=item B<plugExists(I<$name>)

returns the requested plugin object.

=cut

sub plugExists {
	my ($self, $plug) = @_;
	return exists $self->{PLUGINS}->{$plug}
}

=item B<plugGet>(I<$name>)

returns the requested plugin object.

=cut

sub plugGet {
	my ($self, $plug) = @_;
	return $self->{PLUGINS}->{$plug}
}

=item B<plugList>

returns a sorted list of loaded plugins.

=cut

sub plugList {
	my $plugs = $_[0]->{PLUGINS};
	return sort keys %$plugs
}

=item B<plugLoad>(I<$name>)

Loads the plugin; returns 1 if succesfull;

=cut

sub plugLoad {
	my ($self, $plug) = @_;
	return if $self->plugExists($plug);
	my $obj;
	my $modname = "Tk::AppWindow::Plugins::$plug";
	my $app = $self->GetAppWindow;
	eval "use $modname; \$obj = new $modname(\$app);";
	croak $@ if $@;
	if (defined $obj) {
		$self->{PLUGINS}->{$plug} = $obj;
		return 1
	}
	warn "Plugin $plug not loaded";
	return 0
}

=item B<plugUnload>(I<$name>)

Unloads the plugin; returns 1 if succesfull;

=cut

sub plugUnload {
	my ($self, $plug) = @_;
	return unless $self->plugExists($plug);
	my $obj = $self->plugGet($plug);
	if ($obj->Unload) {
		delete $self->{PLUGINS}->{$plug};
		$obj->configureBars;
		return 1
	}
	return 0;
}

=item B<Reconfigure>

Calls Reconfigure on all loaded plugins 1 if all succesfull;

=cut

sub Reconfigure {
	my $self = shift;
	my @plugs = $self->PluginList;
	my $succes = 1;
	for (@plugs) {
		$succes = 0 unless $self->GetPlugin($_)->Reconfigure
	}
	return $succes
}

sub ToolItems {
	my $self = shift;
	my @items = ();
	my @l = $self->plugList;
	for (@l) {
		push @items, $self->plugGet($_)->ToolItems
	}
	return @items;
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. Probably plenty. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
