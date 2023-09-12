package Tk::AppWindow::Ext::Plugins;

=head1 NAME

Tk::AppWindow::Ext::Plugins - load and unload plugins

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
use Pod::Usage;
require Tk::YADialog;
require Tk::AppWindow::PluginsForm;

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
	$self->Require('ConfigFolder');
	$self->addPreConfig(
		-availableplugs => ['PASSIVE', undef, undef, []],
		-plugins => ['PASSIVE', undef, undef, []],
	);

	$self->addPostConfig('DoPostConfig', $self);

	$self->cmdConfig(
		plugsdialog => ['PopPlugsDialog', $self],
	);

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

sub ConfigureBars {
	my ($self, $plug) = @_;
	my $menu = $self->extGet('MenuBar');
	if (defined $menu) {
		my @items = $plug->MenuItems;
		$menu->ReConfigure unless @items eq 0;
	}
	my $tool = $self->extGet('ToolBar');
	if (defined $tool) {
		my @items = $plug->ToolItems;
		$tool->ReConfigure unless @items eq 0;
	}
}

sub DoPostConfig {
	my $self = shift;
	my $file = $self->configGet('-configfolder') . '/plugins';
	if (-e $file) {
		if (open OFILE, "<", $file) {
			while (<OFILE>) {
				my $plug = $_;
				chomp($plug);
				$self->plugLoad($plug);
			}
			close OFILE;
		}
	} else {
		my $plugins = $self->configGet('-plugins');
		for (@$plugins) {
			$self->plugLoad($_);
		}
	}
}

sub MenuItems {
	my $self = shift;
	my @items = ();
	my @l = $self->plugList;
	for (@l) {
		push @items, $self->plugGet($_)->MenuItems
	}
	unless ($self->extExists('Settings')) {
		push @items, (
			[	'menu_normal',		'appname::Quit',		'~Plugins',	'plugsdialog',	'configure',		'F10',	], 
			[	'menu_separator',	'appname::Quit',		'h2'], 
		)
	}
	return @items;
}

sub plugDescription {
	my ($self, $plug) = @_;
	my $file = Tk::findINC("Tk/AppWindow/Plugins/$plug.pm");
	open my $fi, "<", $file or die $!;
	open my $fh, '>', \my $str or die $!;
	pod2usage(
		-exitval => 'NOEXIT',
		-verbose => 99,
		-input => $fi,
		-output => $fh,
		-sections => ['DESCRIPTION'],
	);
	close $fh;
	close $fi;
	$str =~ s/^Description:\n//;
	$str =~ s/\n+$//;
	return $str;
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
	my $modname = $self->plugModname($plug);
	my $app = $self->GetAppWindow;
	eval "use $modname; \$obj = new $modname(\$app);";
	croak $@ if $@;
	if (defined $obj) {
		$self->{PLUGINS}->{$plug} = $obj;
		$self->ConfigureBars($obj);
		return 1
	}
	warn "Plugin $plug not loaded";
	return 0
}

sub plugModname {
	my ($self, $plug) = @_;
	return "Tk::AppWindow::Plugins::$plug"
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
		$self->ConfigureBars($obj);
		return 1
	}
	return 0;
}

sub plugUse {
	my ($self, $plug) = @_;
	my $modname = "Tk::AppWindow::Plugins::$plug";
	eval "use $modname;";
}

sub PopPlugsDialog {
	my $self = shift;
	my $dialog = $self->YADialog(
		-title => 'Configure plugins',
		-buttons => ['Close'],
	);
	$dialog->PluginsForm(
		-pluginsext => $self,
	)->pack(-expand => 1, -fill => 'both');
	$dialog->Show(-popover => $self->GetAppWindow);
	$dialog->destroy;
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

sub SettingsPage {
	my $self = shift;
	return (
		'Plugins' => ['PluginsForm', -pluginsext => $self ]
	)
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

sub Quit {
	my $self = shift;
	my @plugs = $self->plugList;
	my $file = $self->configGet('-configfolder') . '/plugins';
	if (open OFILE, ">", $file) {
		for (@plugs) { print OFILE "$_\n" }
		close OFILE;
	}
	for (@plugs) {
		$self->plugGet($_)->Quit
	}
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
