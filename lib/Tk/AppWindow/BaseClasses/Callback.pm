package Tk::AppWindow::BaseClasses::Callback;

=head1 NAME

Tk::AppWindow::BaseClasses::Callback - providing callbacks

=cut

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

=head1 SYNOPSIS

=over 4

 my $cb = Tk::AppWindow::BaseClasses::Callback->new('MethodName', $owner, @options);
 my $cb = Tk::AppWindow::BaseClasses::Callback->new(sub { do whatever }, @options);
 $cb->Execute(@moreoptions);

=back

=head1 DESCRIPTION

This module provides a simple object to store and execute a code reference. 

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{ANONYMOUS} = 0;
	my $call = shift;
	if ((ref $call) and ($call =~/^CODE/)) {
		$self->{ANONYMOUS} = 1;
	} else {
		my $owner = shift;
		if ($owner->can($call)) {
			$call = $owner->can($call);
			$self->{OWNER} = $owner;
		} else {
			carp "cannot create callback"
		}
	}
	$self->{CALL} = $call;
	$self->{OPTIONS} = \@_;

	bless ($self, $class);
	return $self;
}

=head1 METHODS

=over 4

=item B<Anonymous>

=over 4

returns the state of the Anonymous flag. 

=back

=cut

sub Anonymous {
	my $self = shift;
	return $self->{ANONYMOUS};
}

=item B<Call>($coderef)

=item B<Call>('MethodName')

=over 4

Sets and returns the methodname or code reference.

=cut

sub Call {
	my $self = shift;
	if (@_) { $self->{CALL} = shift; }
	return $self->{CALL};
}

=item B<Execute>(@options)

=over 4

Executes the callback. It checks if the call is a code reference, if yes it invokes it.
If the call is a method name, it looks for that method in owner and then invokes that
method. 

The first parameter given to the call is the value of B<Owner>. Then whatever you feed 
B<Execute>, if any. Finally the list in B<Options> is passed on.

If the B<Anonymous> flag is set it will pass all the options
you specify at B<Execute> and then B<Owner> and B<Options>.

=back

=cut

sub Execute {
	my $self = shift;
	my $call = $self->{CALL};
	my $options = $self->{OPTIONS};
	if ($self->{ANONYMOUS}) {
		return &$call(@_, @$options);
	} else {
		return &$call($self->{OWNER}, @_, @$options);
	}
}

=item B<Options>

=over 4

Sets and returns a reference to a list of options. You normally do not call this method yourself.

=back

=cut

sub Options {
	my $self = shift;
	if (@_) { $self->{OPTIONS} = shift; }
	return $self->{OPTIONS};
}

=item B<Owner>($owner)

=over 4

Returns a reference to the owner of the callback. 

=back

=cut

sub Owner {
   my $self = shift;
   if (@_) { $self->{OWNER} = shift; }
   return $self->{OWNER};
}

=back

=head1 AUTHOR

=over 4

=item Hans Jeuken (hanje at cpan dot org)

=back


=head1 BUGS

=over 4

Unknown. If you find any, please contact the author.

=back

=cut

1;
__END__
