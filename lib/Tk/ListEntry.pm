package Tk::ListEntry;

use strict;
use warnings;
use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'ListEntry';

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;

	$self->SUPER::Populate($args);

	$self->{VALUES} = $values;
	
	my $entry = $self->Entry->pack(-expand => 1, -fill => 'both');
	$self->Advertise(Entry => $entry);
	$entry->bind('<FocusOut>', [$self, 'EntryFocusOut', Ev('d')]);
	$entry->bind('<Button-1>', [$self, 'FlipPop']);
	$entry->bind('<Down>', [$self, 'NavDown']);
	$entry->bind('<Up>', [$self, 'NavUp']);
	$entry->bind('<Return>', [$self, 'Select']);
	$entry->bind('<Escape>', [$self, 'PopDownList']);

	my $tp = $self->Toplevel(
		-borderwidth => 0,
	);
	$tp->overrideredirect(1);
	$tp->withdraw;
	$self->Advertise('ListWindow', $tp);
	$tp->bind('<Motion>', [$self, 'MotionSelect', Ev('x'), Ev('y')]);
	
	my $height = 10;
	if (@$values < $height) { $height = @$values }
	my $listbox = $tp->Scrolled('Listbox',
		-borderwidth => 1,
		-relief => 'sunken',
		-height => $height,
		-listvariable => $values,
		-scrollbars => 'oe',
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$self->bind('<Button-1>', [$self, 'PopDownList']);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$entry],
	);
}

sub EntryFocusOut {
	my ($self, $detail) = @_;
	my $ws = $self->Subwidget('ListWindow');
	my $l = $self->Subwidget('Listbox')->Subwidget('listbox');
	my $fc = $self->focusCurrent;
	unless (defined $fc) {
		$self->PopDownList;
	} else {
		unless ($fc->focusCurrent eq $l) {
			$self->PopDownList;
		} 
	}
}

sub FlipPop {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	if ($w->state eq 'withdrawn') {
		$self->PopUpList
	} else {
		$self->PopDownList
	}
}

sub GetIndex {
	my ($self, $val) = @_;
	my $values = $self->{VALUES};
	my ($index) = grep { $values->[$_] eq $val } (0 .. @$values - 1);
	return $index
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	$list->selectionSet('@' . "$x,$y");
}

sub NavDown {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	my $l = $self->Subwidget('Listbox');
	if ($w->state eq 'withdrawn') {
		$self->PopUpList;
			$l->selectionClear(0, 'end');
			$l->selectionSet(0);
	} else {
		my ($sel) = $l->curselection;
		$sel ++;
		my $val = $self->{VALUES};
		unless ($sel >= @$val) {
			$l->selectionClear(0, 'end');
			$l->selectionSet($sel);
			$l->see($sel);
		}
	}
}

sub NavUp {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	my $l = $self->Subwidget('Listbox');
	if ($w->state eq 'withdrawn') {
		$self->PopUpList;
			$l->selectionClear(0, 'end');
			$l->selectionSet(0);
	} else {
		my $l = $self->Subwidget('Listbox');
		my ($sel) = $l->curselection;
		$sel--;
		unless ($self < 0) { 
			$l->selectionClear(0, 'end');
			$l->selectionSet($sel);
			$l->see($sel);
		}
	}
}

sub PopDownList {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	$w->withdraw;
	$self->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
}

sub PopUpList {
	my $self = shift;

	my $entry = $self->Subwidget('Entry');
	my $lb = $self->Subwidget('Listbox');
	my $w = $self->Subwidget('ListWindow');

	my $screenwidth = $self->vrootwidth;
	my $screenheight = $self->vrootheight;

	my $height = $lb->reqheight;
	my $width = $entry->width;
	
	my $x = $entry->rootx;
	my $origy = $entry->rooty;

	my $y;
	if ($origy + $entry->height + $height > $screenheight) {
		$y = $origy - $height;
	} else {
		$y = $origy + $entry->height;
	}
	
	$w->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
	$lb->selectionClear(0, 'end');
	my $curval = $entry->get;
	my $index = $self->GetIndex($curval);
	$index = 0 unless defined $index;
	$lb->selectionSet($index);
	$w->deiconify;
	$w->raise;
	$self->{'_BE_grabinfo'} = $w->grabSave;
	$self->grabGlobal;
}

sub Select {
	my $self = shift;

	my $entry = $self->Subwidget('Entry');
	my $list = $self->Subwidget('Listbox');

	my $item = $list->get($list->curselection);
	$entry->delete(0, 'end');
	$entry->insert('end', $item);
	$self->PopDownList;
}

sub Validate {
	my $self = shift;
	my $txt = $self->Subwidget('Entry')->get;
	my $values = $self->{VALUES};
	return grep(/^$txt$/, @$values)
}

1;
