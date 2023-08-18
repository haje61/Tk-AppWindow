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

=over 4

=item B<CanQuit>

Tests all plugins if they successfully unload.
returns 1 if succesful 

=cut

sub CanQuit {
	my $self = shift;
	my @plugs = $self->PluginList;
	my $close = 1;
	for (@plugs) {
		$close = 0 unless $self->GetPlugin($_)->CanQuit
	}
	return $close
}

sub DoPostConfig {
	my $self = shift;
	my $plugins = $self->configGet('-plugins');
	for (@$plugins) {
		$self->PluginLoad($_);
	}
}

=item B<GetPlugin>(I<$name>)

returns the requested plugin object.

=cut


sub GetPlugin {
	my ($self, $plug) = @_;
	return $self->{PLUGINS}->{$plug}
}

=item B<PluginList>

returns a sorted list of loaded plugins.

=cut

sub PluginList {
	my $plugs = $_[0]->{PLUGINS};
	return sort keys %$plugs
}

=item B<PluginLoad>(I<$name>)

Loads the plugin; returns 1 if succesfull;

=cut

sub PluginLoad {
	my ($self, $plug) = @_;
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

=item B<PluginLoad>(I<$name>)

Loads the plugin; returns 1 if succesfull;

=cut

sub PluginUnload {
	my ($self, $plug) = @_;
	my $obj = $self->GetPlugin($plug);
	if ($obj->UnLoad) {
		delete $self->{PLUGINS}->{$plug};
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
