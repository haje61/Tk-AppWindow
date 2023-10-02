package Tk::AppWindow::BaseClasses::ContentManager;

=head1 NAME

Tk::AppWindow::BaseClasses::ContentManager - baseclass for content handling

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'ContentManager';

use File::Basename;


=head1 SYNOPSIS

 #This is useless
 require Tk::AppWindow::BaseClasses::ContentManager;
 my $handlerplug = $app->ContentManager->pack;

 #This is what you should do
 package MyContentHandler
 use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
 Construct Tk::Widget 'MyContentHandler';

=head1 DESCRIPTION

This is an opaque base class to help you create a content manager for your application.

It is Tk::Frame based and you can inherit it as a Tk mega widget;

The methods below are used by the extensions MDI and SDI. It is for you to make
them do the right stuff by overriding them.

=head1 CONFIG VARIABLES

=over 4

=item B<-extionsion>

Reference to the document interface extension (MDI, SDI or other) that is creating the 
content handler.

This option is mandatory!

=back

=head1 METHODS

=over 4

=cut

sub Populate {
	my ($self,$args) = @_;
	
	my $ext = delete $args->{'-extension'};
	carp "Option -extension mustt be specified" unless defined $ext;
	
	$self->SUPER::Populate($args);
	$self->{EXT} = $ext;

	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
	$self->after(20, ['ConfigureCM', $self]);
}

=item B<Close>

=cut

sub Close {
	my $self = shift;
	$self->doClear;
	return 1
}

sub ConfigureCM {
	my $self = shift;
	my $ext = $self->Extension;
	my $cmopt = $ext->configGet('-contentmanageroptions');
	my @o = @$cmopt; #hack, i do not know why this is needed.
	for (@o) {
		my $val = $ext->configGet($_);
		$self->configure($_, $val) if ((defined $val) and ($val ne ''));
	}
}

sub ConfigureBindings {
	my $self = shift;
	$self->{BINDINGS} = {@_}
}

=item B<CWidg>

=cut

sub CWidg {
	my $self = shift;
	$self->{WIDGET} = shift if @_;
	return $self->{WIDGET};
}

sub DiskModified {
	my $self = shift;
	return 0
}

=item B<doClear>

=cut

sub doClear{
}

=item B<doLoad>

=cut

sub doLoad {
	return 1
}

=item B<doSave>

=cut

sub doSave {
	return 1
}

=item B<doSelect>

=cut

sub doSelect {
}

=item B<Extension>

=cut

sub Extension {
   my $self = shift;
   if (@_) { $self->{EXT} = shift; }
   return $self->{EXT};
}

=item B<IsModified>

=cut

sub IsModified {
	my $self = shift;
	return 0
}

=item B<Load>

=cut

sub Load {
	my ($self, $file) = @_;
	return $self->doLoad($file);
}

=item B<Save>

=cut

sub Save {
	my ($self, $file) = @_;
	return $self->doSave($file);
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

