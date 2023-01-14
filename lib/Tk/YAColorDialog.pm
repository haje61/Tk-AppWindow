package Tk::YAColorDialog;

=head1 NAME

Tk::YAColorDialog - Yet another color dialog

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Tk;
require Tk::NoteBook;

use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'YAColorDialog';

my @colspaces = (
	[qw[RGB Red Green Blue]],
	[qw[CMY Cyan Magenta Yellow]],
);

my %updates = (
	Red => 'Cyan',
	Green => 'Magenta',
	Blue => 'Yellow',
	Cyan => 'Red',
	Magenta => 'Green',
	Yellow => 'Blue',
);

=head1 SYNOPSIS

=over 4

 require Tk::YAColorDialog;
 my $dialog = $window->YAColorDialog;
 my $but = $dialog->Show;
 if ($but eq 'Select') {
	$color = $dialog->Get;
 }

=back

=head1 DESCRIPTION

=over 4

Provides a basic color dialog. Less noisy than Tk::ColorDialog.
Inherits L<Tk::YADialog>.

=back

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-initialcolor>

=over 4

Set the initial color for the dialog.

=back

=back

=cut

sub Populate {
	my ($self,$args) = @_;

	unless (exists $args->{'-buttons'}) {
		$args->{'-buttons'} = ['Select', 'Close'];
	}

	my $bitsperchannel = delete $args->{'-bitsperchannel'};
	$bitsperchannel = 8 unless defined $bitsperchannel;
	$self->{BITSPERCHANNEL} = $bitsperchannel;
	
	my $initialcolor = delete $args->{'-initialcolor'};
	
	my $nodepthselect = delete $args->{'-nodepthselect'};
	$nodepthselect = 0 unless defined $nodepthselect;

	$self->{BITSPERCHANNEL} = $bitsperchannel;
	
	$self->SUPER::Populate($args);

	unless ($nodepthselect) {
		my $bpcframe = $self->Frame->pack(-fill => 'x');
		$bpcframe->Label(-text => 'Depth:')->pack(-side => 'left', -padx => 2, -pady => 2);
		for (4, 8, 12, 16) {
			my $depth = $_;
			$bpcframe->Radiobutton(
				-text => $depth,
				-value => $depth,
				-command => ['BitsPerChannel', $self, $depth],
				-variable => \$bitsperchannel,
			)->pack(-side => 'left', -padx => 2, -pady => 2);
		}
	}

	my $nb = $self->NoteBook->pack(-expand => 1, -fill => 'both');
	my %varpool = ();
	for (@colspaces) {
		my @space = @$_;
		my $lab = shift @space;
		my $page = $nb->add($lab, -label => $lab);
		for (@space) {
			my $slframe = $page->Frame->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'y');
			my $var = 0;
			$varpool{$_} = \$var;
			my $slider = $slframe->Scale(
				-from => $self->MaxChannelValue, 
				-to => 0,
				-orient => 'vertical',
				-command => ['ChannelUpdate', $self, $_],
				-variable => \$var,
			)->pack(-pady => 2, -expand => 1, -fill => 'y');
			$self->Advertise($_, $slider);
			$slframe->Label(-width => 8, -text => $_)->pack;
		}
	}
	$self->{VARPOOL} = \%varpool;

	my $coldispl = $self->Frame->pack(-fill => 'x', -padx => 2, -pady => 2);
	my $display = $coldispl->Label(
		-width => 8,
		-relief => 'sunken',
		-borderwidth => 3,
	)->pack(-side => 'left', -expand => 1, -padx => 2, -pady => 2, -fill => 'y');
	$self->Advertise('Display', $display);
	my $text = '';
	my $entry = $coldispl->Entry(
		-textvariable => \$text,
	)->pack(-side => 'left', -expand => 1, -fill => 'x', -padx => 2, -pady => 2);
	$self->Advertise('Entry', $entry);
	
	$self->ConfigSpecs(
		-entryerrorcolor => ['PASSIVE', undef, undef, '#FF0000'],
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
		DEFAULT => ['SELF'],
	);
	$self->after(1, ['AutoUpdate', $self]);
	if (defined $initialcolor) {
		$self->after(100, sub {
			my $depth = $self->ColorDepth($initialcolor);
			if ((defined $depth) and ($depth ne $self->{BITSPERCHANNEL})) {
				$self->BitsPerChannel($depth, 1);
				$bitsperchannel = $depth;
			}
			my $var = $self->Subwidget('Entry')->cget('-textvariable');
			$$var = $initialcolor;
		});
	}
}

=head1 METHODS

=over 4

=cut

sub AutoUpdate {
	my $self = shift;
	my $var = $self->Subwidget('Entry')->cget('-textvariable');
	if (($$var ne $self->CompoundColor) and $self->Validate) {
		my @rgb = $self->Hex2RGB($$var);
		my %cl = (
			Red => $rgb[0],
			Green => $rgb[1],
			Blue => $rgb[2],
		);
		my $pool = $self->{VARPOOL};
		for (keys %cl) {
			my $var = $pool->{$_};
			$$var = $cl{$_};
			$self->ChannelUpdate($_);
		}
	}
	$self->EntryUpdate;
	$self->after(500, ['AutoUpdate', $self, 1]);
}

sub BitsPerChannel {
	my ($self, $value, $noupdate) = @_;
	if (defined $value) {
		$noupdate = 0 unless defined $noupdate;
		my $oldmax = $self->MaxChannelValue;
		$self->{BITSPERCHANNEL} = $value;
		my $newmax = $self->MaxChannelValue;
		my $ratio = $newmax/$oldmax;
		my $varpool = $self->{VARPOOL};
		for (keys %updates) {
			my $var = $varpool->{$_};
			my $val = $$var;
			$self->Subwidget($_)->configure(-from => $newmax);
			$$var = $val * $ratio;
		}
		unless ($noupdate) {
			my $var = $self->Subwidget('Entry')->cget('-textvariable');
			$$var = $self->CompoundColor;
			$self->EntryUpdate;
		}
	}
	return $self->{BITSPERCHANNEL}
}

sub ChannelUpdate {
	my ($self, $channel) = @_;
	my $maxval = $self->MaxChannelValue;
	my $caller = $self->{VARPOOL}->{$channel};
	my $target = $self->{VARPOOL}->{$updates{$channel}};
	$$target = $maxval - $$caller;
	my $var = $self->Subwidget('Entry')->cget('-textvariable');
	$$var = $self->CompoundColor;
	$self->EntryUpdate;
}

=item B<ColorDepth>I<($color)>

=over 4

Returns the color depth of $color.

=back

=cut

sub ColorDepth {
	my ($self, $color) = @_;
	$color =~ s/^\#//;
	my %valid = (
		3 => 4,
		6 => 8,
		9 => 12,
		12 => 16
	);
	my $length = length($color);
	return $valid{$length} if exists $valid{$length};
	return undef
}

sub CompoundColor {
	my $self = shift;
	my $pool = $self->{VARPOOL};
	my $vred = $pool->{'Red'};
	my $red = $self->HexString($$vred);
	my $vgreen = $pool->{'Green'};
	my $green = $self->HexString($$vgreen);
	my $vblue = $pool->{'Blue'};
	my $blue = $self->HexString($$vblue);
	return "#$red$green$blue";
}

sub EntryUpdate {
	my $self = shift;
	my $entry = $self->Subwidget('Entry');
	my $display = $self->Subwidget('Display');
	my $var = $entry->cget('-textvariable');
	if ($self->Validate) {
		$self->Subwidget('Display')->configure(-background => $$var);
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
		$self->Subwidget('Select')->configure('-state' => 'normal'); 
	} else {
		$self->Subwidget('Display')->configure(-background => $self->cget('-background'));
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryerrorcolor'));
		$self->Subwidget('Select')->configure('-state' => 'disabled'); 
	}
}

=item B<Get>

=over 4

Returns the current value.

=back

=cut

sub Get {
	my $var = $_[0]->Subwidget('Entry')->cget('-textvariable');
	return $$var
}

=item B<Hex2RGB>I<($hex)>

=over 4

Returns rgb list $hex value.

=back

=cut

sub Hex2RGB {
	my ($self, $hex) = @_;
	$hex =~ s/^(\#|Ox)//;
	
	my $length = length($hex) / 3;
	$_ = $hex;
	my ($r, $g, $b) = m/(\w{$length})(\w{$length})(\w{$length})/;
	my @rgb = ();
	$rgb[0] = CORE::hex($r);
	$rgb[1] = CORE::hex($g);
	$rgb[2] = CORE::hex($b);
	return @rgb
}

sub HexString {
	my ($self, $num) = @_;
	my $length = $self->{BITSPERCHANNEL} / 4;
	my $hex = substr(sprintf("0x%X", $num), 2);
	while (length($hex) < $length) { $hex = "0$hex" }
	return $hex
}

sub MaxChannelValue {
	return (2**$_[0]->{BITSPERCHANNEL}) - 1
}

sub Validate {
	my $self = shift;
	my $var = $self->Subwidget('Entry')->cget('-textvariable');
	return 1 unless defined $var;
	my $repeat = $self->{BITSPERCHANNEL} / 4;
	return $$var =~ /^#(?:[0-9a-fA-F]{3}){$repeat}$/
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
