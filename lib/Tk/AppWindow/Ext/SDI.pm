package Tk::AppWindow::Ext::SDI;

=head1 NAME

Tk::AppWindow::Ext::SDI - single document interface

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";
use File::Basename;
use File::Spec;
require Tk::YAMessage;

use base qw( Tk::AppWindow::Ext::MDI );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -contentmanagerclass => 'Tk::MyContentHandler',
    -extensions => ['SDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a single document interface to your application.
It is written as a multiple document interface with a maximum of one document.
This makes it easy for L<Tk::AppWindow::Ext::MDI> to inherit SDI.

When L<Tk::AppWindow::Ext::MenuBar> is loaded it creates menu 
entries for creating, opening, saving and closing files. It also
maintaines a history of recentrly closed files.

When L<Tk::AppWindow::Ext::ToolBar> is loaded it creates toolbuttons
for creating, opening, saving and closing files.

You should define a content handler based on the abstract
baseclass L<Tk::AppWindow::BaseClasses::ContentManager>. See also there.

=head1 CONFIG VARIABLES

=over 4

=item B<-contentmanagerclass>

This one should always be specified and you should always define a 
content manager class inheriting L<Tk::AppWindow::BaseClasses::ContentManager>.
This base class is a valid Tk widget.

=item B<-contentmanageroptions>

The possible options to pass on to the contentmanager.
These will also become options to the main application.

=item B<-maxhistory>

Default value is 12.

=item B<-filetypes>

Default value is "All files|*"

=item B<-historymenupath>

Specifies the default location in the main menu of the history menu.
Default value is File::Open recent. See also L<Tk::AppWindow::Ext::MenuBar>.

=item B<-readonly>

Default value 0. 

=back

=head1 COMMANDS

=over 4

=item B<doc_close>

=item B<doc_new>

=item B<doc_open>

=item B<doc_save>

=item B<doc_save_as>

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	return $self;
}

=head1 B<METHODS>

=over 4

=cut

sub CmdDocNew {
	my $self = shift;
	if ($self->CmdDocClose) {
		return $self->SUPER::CmdDocNew(@_)
	}
	return 0
}

sub ContentSpace {
	return $_[0]->WorkSpace;
}

sub CreateInterface {}

sub MenuSaveAll {
	return ()
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

