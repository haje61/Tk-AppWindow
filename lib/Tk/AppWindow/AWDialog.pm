package Tk::AppWindow::AWDialog;

use Tk;
use base qw(Tk::Derived Tk::Toplevel);
Construct Tk::Widget 'AWDialog';

sub Populate {
	my ($self,$args) = @_;

	my $buttons = delete $args->{'-buttons'};
	$buttons = [] unless defined $buttons;
	my $padding = delete $args->{'-padding'};
	$padding = 20 unless defined $padding;
	my $plugin = delete $args->{'-plugin'};

	$self->{DEFAULTBUTTON} = delete $args->{'-defaultbutton'};

	$self->SUPER::Populate($args);
	
	$self->{PADDING} = $padding;
	$self->{PLUGIN} = $plugin;
	$self->{PRESSED} = '';
	
	$self->protocol('WM_DELETE_WINDOW', sub { $self->CancelDialog });
	$self->bind('<Escape>' => sub { $self->CancelDialog });

	my @pad = (-padx => $padding, -pady => $padding);
	my $bframe = $self->Frame->pack(-side => 'bottom', -fill => 'x');
	$self->Advertise('buttonframe', $bframe);
	
	for (reverse @$buttons) {
		my $but = $_;
		if ($but =~ /^ARRAY/) {
			my $b =$bframe->Button(
				-text => $but->[0],
				-command => $$but->[1],
			)->pack(-side => 'right', -padx => $padding, -pady => $padding);
			$self->Advertise($but->[0], $b);
		} else {
			my $b = $bframe->Button(
				-text => $but,
				-command => sub { $self->Pressed($but) },
			)->pack(-side => 'right', -padx => $padding, -pady => $padding);
			$self->Advertise($but, $b);
		}
		my $lab = pop @$buttons;
	}
	$self->transient($self->Parent->toplevel);
	$self->withdraw;
	$self->ConfigSpecs(
		-command => ['CALLBACK', undef, undef, sub {}],
		DEFAULT => ['SELF'],
	);

}

sub ButtonPack {
	my ($self, $but) = @_;
	my $pad = $self->{PADDING};
	$but->pack(
		-side => 'right',
		-padx => $pad,
		-pady => $pad,
	);
}

sub CancelDialog {
	$_[0]->Pressed('*Cancel*');
}

sub Get { return $_[0]->{PRESSED} }

sub Plugin { return $_[0]->{PLUGIN} }

sub Pressed {
	my $self = shift;
	if (@_) {
		$self->{PRESSED} = shift;
		$self->withdraw;
	}
	return $self->{PRESSED}
}

sub Show {
	my $self = shift;
	my ($grab) = @_;
	my $old_focus = $self->focusSave;
	my $old_grab = $self->grabSave;

	shift if defined $grab && length $grab && ($grab =~ /global/);
	$self->Popup(@_);

	Tk::catch {
		if (defined $grab && length $grab && ($grab =~ /global/)) {
			$self->grabGlobal;
		} else {
			$self->grab;
		}
	};
	if (my $focusw = $self->cget(-focus)) {
		$focusw->focus;
	} elsif (defined $self->{DEFAULTBUTTON}) {
		$self->Subwidget($self->{DEFAULTBUTTON})->focus;
	} else {
		$self->focus;
	}
	$self->Wait;
	&$old_focus;
	&$old_grab;
	return $self->{PRESSED};
}

sub Wait {
	my $self = shift;
	$self->Callback(-showcommand => $self);
	$self->waitVariable(\$self->{PRESSED});
	$self->grabRelease if Tk::Exists($self);
	$self->withdraw if Tk::Exists($self);
	$self->Callback(-command => $self->{PRESSED});
}

1;
