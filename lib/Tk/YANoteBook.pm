package NameTab;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'NameTab';

sub Populate {
	my ($self,$args) = @_;
	
	my $closebutton = delete $args->{'-closebutton'};
	$closebutton = 0 unless defined $closebutton;

	$self->SUPER::Populate($args);
	my $l = $self->Label(
	)->pack(
		-side => 'left',
		-padx => 2,
		-pady => 6,
	);
	$self->Advertise('Label' => $l);

	$self->bind('<Motion>', [$self, 'TabMotion', Ev('x'), Ev('y')]);
	$l->bind('<Motion>', [$self, 'ItemMotion', $l, Ev('x'), Ev('y')]);

	$self->bind('<Button-1>', [$self, 'OnClick']);
	$l->bind('<Button-1>', [$self, 'OnClick']);

	$self->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	$l->bind('<ButtonRelease-1>', [$self, 'OnRelease']);
	
	my $b;
	if ($closebutton) {
		$b = $self->Button(
			-relief => 'flat',
		)->pack(
			-side => 'left',
			-padx => 2,
			-pady => 2,
		);
		$b->bind('<Motion>', [$self, 'ItemMotion', $b, Ev('x'), Ev('y')]);
	}
	
	$self->ConfigSpecs(
		-command => [$b],
		-image => [$b],
		-name => ['PASSIVE', undef, undef, ''],
		-clickcall => ['CALLBACK', undef, undef, sub {}],
		-motioncall => ['CALLBACK', undef, undef, sub {}],
		-releasecall => ['CALLBACK', undef, undef, sub {}],
		-title => [{-text => $l}, undef, undef, $title],
		-titleimg => [{-image => $l}, undef, undef, undef],
		DEFAULT => ['SELF'],
	);
}

sub ItemMotion {
	my ($self, $item, $x, $y) = @_;
	$x = $x + $item->x;
	$y = $y + $item->y;
	$self->TabMotion($x, $y);
}

sub OnClick {
	my $self = shift;
	my $name = $self->cget('-name');
	$self->Callback('-clickcall', $name);
}

sub OnRelease {
	my $self = shift;
	my $name = $self->cget('-name');
	$self->Callback('-releasecall', $name);
}

sub TabMotion {
	my ($self, $x, $y) = @_;
	my $name = $self->cget('-name');
	$self->Callback('-motioncall', $name, $x, $y);
}

package Tk::YANoteBook;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'YANoteBook';

sub Populate {
	my ($self,$args) = @_;
	
	my $tabside = delete $args->{-'tabside'};
	$tabside = 'top' unless defined $tabside;

	my @barpack = ();
	my @tabpack = ();
	my $buttonside;
	if (($tabside eq 'top') or ($tabside eq 'bottom')) {
		$self->{TABSIDE} = 'left';
		push @barpack, -side => $tabside, -fill => 'x';
		push @tabpack, -side => 'left', -fill => 'x', -expand => 1;
		$buttonside = 'right';
	} elsif (($tabside eq 'left') or ($tabside eq 'right')) {
		$self->{TABSIDE} = 'top';
		push @barpack, -side => $tabside, -fill, 'y';
		push @tabpack, -side => 'top', -fill => 'y', -expand => 1;
		$buttonside = 'bottom';
	} else {
		die "illegal value '$tabside' for -tabside. Must be top, bottom, left or right'"
	}

	$self->SUPER::Populate($args);
	
	my $barframe = $self->Frame(
	)->pack(@barpack);

	my $tabframe = $barframe->Frame(
	)->pack(@tabpack, -expand => 1);
	$self->Advertise('TabFrame' => $tabframe);

	my $morebutton = $barframe->Button(
		-text => 'More',
		-relief => 'flat',
		-command => ['ListPop', $self],
	)->pack(
		-side => $buttonside,
		-padx => 2,
		-pady => 2,
	);
	$self->Advertise('MoreButton' => $morebutton);

	my $tp = $self->Toplevel(
		-borderwidth => 0,
	);
	$tp->overrideredirect(1);
	$tp->withdraw;
	$self->Advertise('ListWindow', $tp);
	$tp->bind('<Escape>', [$self, 'ListPopDown']);
	
	my @values = ();
	my $listbox = $tp->Scrolled('Listbox',
		-borderwidth => 1,
		-relief => 'sunken',
		-listvariable => \@values,
		-scrollbars => 'osoe',
	)->pack(-expand => 1, -fill => 'both');
	$self->Advertise('Listbox', $listbox);
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select', Ev('x'), Ev('y')]);
	$self->bind('<Button-1>', [$self, 'ListPopDown']);

	my $pageframe = $self->Frame->pack(-side => $tabside, -expand => 1, -fill => 'both');
	$self->Advertise('PageFrame' => $pageframe);

	$self->bind('<Configure>', [$self, 'UpdateTabs']);
	$self->{ACTIVE} = 0;
	$self->{DISPLAYED} = [];
	$self->{INMAINLOOP} = 0;
	$self->{PAGES} = {};
	$self->{SELECTED} = undef;
	$self->{UNDISPLAYED} = \@values;
	$self->{POPPED} = 0;

	$self->ConfigSpecs(
		-closeimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('close_icon.xpm'))],
		-closetabcall => ['CALLBACK', undef, undef, sub { return 1 }],
		-selectoptions => ['PASSIVE', undef, undef, [
			-relief => 'flat',
		]],
		-tabpack => ['PASSIVE', undef, undef, []], 
		-unselectoptions => ['PASSIVE', undef, undef, [
			-relief => 'sunken',
		]],
		DEFAULT => [$self],
	);
	$self->after(1, ['PostInit', $self]);
}

sub AddPage {
	my $self = shift;
	my $name  = shift;
	my %opt = (@_);
	
	my $title = delete $opt{'-title'};
	$title = $name unless defined $title;
	
	my $closeb = delete $opt{'-closebutton'};
	$closeb = 0 unless defined $closeb;
	my $uo = $self->cget('-unselectoptions');
	my @bopt = (@$uo);
	if ($closeb) {
		push @bopt,
			-closebutton => 1,
			-command => ['DeletePage', $self, $name],
			-image => $self->cget('-closeimage');
	}
	
# 	$self->update;
	my $tab = $self->Subwidget('TabFrame')->NameTab(@bopt,
		-name => $name,
		-title => $title,
		-clickcall => ['ClickCall', $self],
		-motioncall => ['MotionCall', $self],
		-releasecall => ['ReleaseCall', $self],
		-borderwidth => 1,
	);
	my $ud = $self->{UNDISPLAYED};
	push @$ud, $name;
	my $page = $self->Subwidget('PageFrame')->Frame;

	my $pages = $self->{PAGES};
	$self->{PAGES}->{$name} = [$tab, $page];
	$self->UpdateTabs if $self->{INMAINLOOP};

	return $page
}

sub ClickCall {
	my ($self, $name) = @_;
	$self->{ACTIVE} = 1;
	$self->SelectPage($name);
}

sub DeletePage {
	my ($self, $name) = @_;
	unless ($self->PageExists($name)) {
		warn "Page '$name' does not exist\n";
		return
	}
	if ($self->Callback('-closetabcall', $name)) {
		$self->UnSelectPage;
		if ($self->IsDisplayed($name)) {
			my $dp = $self->{DISPLAYED};
			my ($pos) = grep { $dp->[$_] eq $name } 0 .. @$dp - 1;
			splice(@$dp, $pos, 1);
		} else {
			my $ud = $self->{UNDISPLAYED};
			my ($pos) = grep { $ud->[$_] eq $name } 0 .. @$ud - 1;
			splice(@$ud, $pos, 1);
		}
		my $pg = delete $self->{PAGES}->{$name};
		$pg->[0]->destroy;
		$pg->[1]->destroy;
		$self->UpdateTabs;
	}
}

sub FindTabPos {
	my ($self, $name) = @_;
	my $dp = $self->{DISPLAYED};
	my $last = @$dp - 1;
	my ($index) = grep { $dp->[$_] eq $name } 0 .. $last;
	return $index
}

sub GetTab {
	my ($self, $name) = @_;
	return $self->{PAGES}->{$name}->[0];
}

sub IsDisplayed {
	my ($self, $name) = @_;
	my $dp = $self->{DISPLAYED};
	if (my ($match) = grep $_ eq $name, @$dp) {
		return 1
	}
	return 0
}

sub IsFull {
	my ($self, $newtab) = @_;
	my $last = $self->LastDisplayed;
	if (defined $last) {
		my $tab = $self->GetTab($last);
		if ($self->{TABSIDE} eq 'left') {
			my $pos = $tab->x + $tab->width;
			$pos = $pos + $newtab->reqwidth if defined $newtab;
			my $tabwidth = $self->Subwidget('TabFrame')->width;
			return $pos >= $tabwidth
		} else {
			my $pos = $tab->y + $tab->height;
			$pos = $pos + $newtab->reqheight if defined $newtab;
			my $tabheight = $self->Subwidget('TabFrame')->height;
			return $pos >= $tabheight
		}
	}
	return 0;
}

sub LastDisplayed {
	my $self = shift;
	my $dp = $self->{DISPLAYED};
	return $dp->[@$dp - 1] if (@$dp);
	return undef
}

sub ListPop {
	my $self = shift;
	if ($self->{POPPED}) {
		$self->ListPopDown;
	} else {
		my $entry = $self->Subwidget('MoreButton');
		my $lb = $self->Subwidget('Listbox');
		my $w = $self->Subwidget('ListWindow');
		my $pgs = $self->{PAGES};
		my @pages = sort keys %$pgs;
		my $values = $self->{LISTVALUES};
		$values = [];
		for (@pages) {
			push @$values, $_ unless $self->IsDisplayed($_);
		}
		if (@$values) {
			my $pf = $self->Subwidget('PageFrame');
			my $width = $pf->width;
			my $height = $pf->height;
			my $x = $pf->rootx;
			my $y = $pf->rooty;
			$w->geometry(sprintf('%dx%d+%d+%d', $width, $height, $x, $y));
			$lb->selectionClear(0, 'end');
			my $curval = '';
			$w->deiconify;
			$w->raise;
			$w->focus;
			$self->{'_BE_grabinfo'} = $w->grabSave;
			$self->grabGlobal;
		}
		$self->{POPPED} = 1;
	}
}

sub ListPopDown {
	my $self = shift;
	my $w = $self->Subwidget('ListWindow');
	$w->withdraw;
	$self->grabRelease;
	if (ref $self->{'_BE_grabinfo'} eq 'CODE') {
		$self->{'_BE_grabinfo'}->();
		delete $self->{'_BE_grabinfo'};
	}
	$self->{POPPED} = 0;
}

sub _MoveNext {
	my ($self, $name) = @_;
	my $tab = $self->GetTab($name);
	my $pos = $self->FindTabPos($name);
	my $dp = $self->{DISPLAYED};
	if ($pos < @$dp - 1) {
		my $next = $self->GetTab($dp->[$pos + 1]);
		$self->PackTab($name, -after => $next);
		splice(@$dp, $pos, 1);
		splice(@$dp, $pos + 1, 0, $name);
	}
}

sub _MovePrevious {
	my ($self, $name) = @_;
	my $tab = $self->GetTab($name);
	my $pos = $self->FindTabPos($name);
	my $dp = $self->{DISPLAYED};
	if ($pos > 0) {
		my $prev = $self->GetTab($dp->[$pos - 1]);
		$self->PackTab($name, -before => $prev);
		splice(@$dp, $pos, 1);
		splice(@$dp, $pos - 1, 0, $name);
	}
}

sub MotionCall {
	my ($self, $name, $x, $y) = @_;
	if ($self->{ACTIVE}) {
		my $tab = $self->GetTab($name);
		unless (exists $self->{CURSORSAVE}) {
			$self->{CURSORSAVE} = $tab->cget('-cursor');
			$tab->configure(-cursor => 'hand1');
		}
		my $nmult = 1.5;
		my $pmult = -0.5;
		if (($self->{TABSIDE} eq 'left') or ($self->{TABSIDE} eq 'right')) {
			my $width = $tab->width;
			if ($x > ($width * $nmult)) {
				$self->_MoveNext($name);
			} elsif ($x < ($width * $pmult)) {
				$self->_MovePrevious($name);
			}
		} else {
			my $height = $tab->height;
			if ($y > ($height * $nmult)) {
				$self->_MoveNext($name);
			} elsif ($y < ($height * $pmult)) {
				$self->_MovePrevious($name);
			}
		}
	}
}

sub MotionSelect {
	my ($self, $x, $y) = @_;
	my $list = $self->Subwidget('Listbox');
	$list->selectionClear(0, 'end');
	$list->selectionSet('@' . "$x,$y");
}

sub PackTab {
	my $self = shift;
	my $name = shift;
	my $o = $self->cget('-tabpack');
	my $tabframe = $self->Subwidget('TabFrame');
	my $tab = $self->GetTab($name);
	$tab->pack(@_, @$o,
		-side => $self->{TABSIDE},
	);
}

sub PageExists {
	my ($self, $name) = @_;
	return exists $self->{PAGES}->{$name};
}

sub PostInit {
	my $self = shift;
	$self->{INMAINLOOP} = 1;
	$self->UpdateTabs;
	my $dp = $self->{DISPLAYED};
	$self->SelectPage($dp->[0]) if (@$dp);
}

sub ReleaseCall {
	my ($self, $name) = @_;
	my $tab = $self->GetTab($name);
	$self->{ACTIVE} = 0;
	if (exists $self->{CURSORSAVE}) {
		$tab->configure(-cursor => $self->{CURSORSAVE});
		delete $self->{CURSORSAVE};
	}
	delete $self->{MOTION};
}

sub Select {
	my $self = shift;
	my $list = $self->Subwidget('Listbox');
	my $item = $list->get($list->curselection);
	$self->SelectPage($item);
	$self->ListPopDown;
}

sub SelectPage {
	my ($self, $name) = @_;
	my $page = $self->{PAGES}->{$name};
	if (defined $page) {
		$self->UnSelectPage;
		unless ($self->IsDisplayed($name)) {
			my $ud = $self->{UNDISPLAYED};
			my @undisp = @$ud;
			my ($index) = grep { $undisp[$_] eq $name } 0 .. $#undisp;
			splice(@$ud, $index, 1);
			my $dp = $self->{DISPLAYED};
			my @options = ();
			push @options, -before => $self->GetTab($dp->[0]) if @$dp;
			$self->PackTab($name, @options);
			unshift @$dp, $name;
			$self->UpdateTabs;
		}
		my ($tab, $frame) = @$page;
		my $o = $self->cget('-selectoptions');
		$tab->configure(@$o);
		$frame->pack(-expand => 1, -fill => 'both');
# 		$frame->update;
		$self->{SELECTED} = $name;
	} else {
		warn "Page $name does not exist"
	}
}

sub TabPosition {
	my ($self, $name) = @_;
	my $dp = $self->{DISPLAYED};
	my $size = @$dp - 1;
	my ($index) = grep { $dp->[$_] eq $name } 0 .. $size;
	return $index
}

sub UnSelectPage {
	my $self = shift;
	my $name = $self->{SELECTED};
	if (defined $name) {
		my $page = $self->{PAGES}->{$name};
		my ($tab, $frame) = @$page;
		my $o = $self->cget('-unselectoptions');
		$tab->configure(@$o);
		$frame->packForget;
		$self->{SELECTED} = undef;
	}
}

sub UpdateTabs {
	my $self = shift;
	my $ud = $self->{UNDISPLAYED};
	my $dp = $self->{DISPLAYED};
	my $notempty = @$dp;
	while ($self->IsFull) {
		my $last = pop @$dp;
		my $tab = $self->GetTab($last);
		$tab->packForget;
		unshift @$ud, $last;
		$self->update;
	}
	return unless @$ud;
	my $name = $ud->[0];
	while ((@$ud) and (not $self->IsFull($self->GetTab($name)))) {
		$self->PackTab($name);
		push @$dp, $name;
		shift @$ud;
		$name = $ud->[0];
		$self->update;
	}
}

1;