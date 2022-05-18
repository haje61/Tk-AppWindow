package Tk::AppWindow::AWSettingsDialog;

use strict;
use warnings;

use Tk;
use base qw(Tk::Derived Tk::AppWindow::AWDialog);
Construct Tk::Widget 'AWSettingsDialog';

require Tk::AppWindow::AWSettingsDialog::CBooleanItem;
require Tk::AppWindow::AWSettingsDialog::CColorItem;
require Tk::AppWindow::AWSettingsDialog::CFileItem;
require Tk::AppWindow::AWSettingsDialog::CFloatItem;
require Tk::AppWindow::AWSettingsDialog::CFolderItem;
require Tk::AppWindow::AWSettingsDialog::CFontItem;
require Tk::AppWindow::AWSettingsDialog::CListItem;
require Tk::AppWindow::AWSettingsDialog::CRadioItem;
require Tk::AppWindow::AWSettingsDialog::CIntegerItem;
require Tk::AppWindow::AWSettingsDialog::CTextItem;
require Tk::LabFrame;

my %typeclasses = (
	boolean => 'CBooleanItem',
	color => 'CColorItem',
	file => 'CFileItem',
	float => 'CFloatItem',
	folder => 'CFolderItem',
	font => 'CFontItem',
	integer => 'CIntegerItem',
	list => 'CListItem',
	radio => 'CRadioItem',
	text => 'CTextItem',
);

sub Populate {
	my ($self,$args) = @_;

	unless (exists $args->{'-buttons'}) {
		$args->{'-buttons'} = ['Close'];
		unless (exists $args->{'-defaultbutton'}) {
			$args->{'-defaultbutton'} = 'Close';
		}
	}
	
	$self->SUPER::Populate($args);
	
	warn "You must supply the -plugin option" unless defined $self->Plugin;

	my $holder = $self->Frame->pack(-expand => 1, -fill => 'both');
	$holder->gridColumnconfigure(1, -weight => 1);
	my @holderstack = ({
		holder => $holder,
		type => '',
		row => 0
	});
	my $notebook;

	my $uo = $self->Plugin->ConfigGet('-useroptions');
	my @useroptions = @$uo;
	my %options = ();
	my @padding = (-padx => 2, -pady => 2);

	my $labelwidth = 0;
	while (@useroptions) {
		my $key = shift @useroptions;
		if (($key eq 'page') or ($key eq 'section')) {
			shift @useroptions;
			next;
		}
		if ($key eq 'end') {
			next;
		}
		my $conf = shift @useroptions;
		my $l = length $conf->[1];
		$labelwidth = $l if $l > $labelwidth;
	}
	print "labelwidth $labelwidth\n";

	@useroptions = @$uo;
	while (@useroptions) {
		my $key = shift @useroptions;

		if ($key eq 'page') {
			my $label = shift @useroptions;
			unless (defined $notebook) {
				$notebook = $holderstack[0]->{holder}->NoteBook->grid(-column => 0, -row => $holderstack[0]->{row}, -columnspan => 2, -sticky => 'nesw');
			}
			my $page = $notebook->add($label, -label => $label);
			my $h = $page->Frame->pack(-fill => 'x');
			$h->gridColumnconfigure(1, -weight => 1);
			$holderstack[0]->{row} ++;
			unshift @holderstack, {
				holder => $h,
				type => 'page',
				row => 0
			};

		} elsif ($key eq 'section') {
			my $label = shift @useroptions;
			my $h = $holderstack[0];
			my $lf = $h->{holder}->LabFrame(
				-label => $label,
				-labelside => 'acrosstop',
			)->grid(@padding, -column => 0, -row => $h->{row}, -columnspan => 2, -sticky => 'nesw');
			$lf->gridColumnconfigure(1, -weight => 1);
			$holderstack[0]->{row} ++;
			unshift @holderstack, {
				holder => $lf,
				type => 'section',
				row => 0
			};
			
		} elsif ($key eq 'end') {
			if ($holderstack[0]->{type} eq 'page') {
				$notebook = undef
			}
			if  (@holderstack > 1) {
				shift @holderstack
			} else {
				warn "Holder stack is already empty"
			}

		} else {
			my $conf = shift @useroptions;
			my ($type, $label, $values) = @$conf;

			$holderstack[0]->{holder}->Label(-width => $labelwidth, -text => $label, -anchor => 'e')->grid(@padding, -column => 0, -row => $holderstack[0]->{row}, -sticky => 'e');

			my $class = $typeclasses{$type};
			my @opts = ();
			if (defined $values) {
				if ((ref $values) and ($values =~/^ARRAY/)) {
					push @opts, -values => $values;
				} else {
					my @vals = $self->Plugin->CommandExecute($values);
					push @opts, -values => \@vals;
				}
			}

			my $widg = $holderstack[0]->{holder}->$class(@opts,
				-plugin => $self->Plugin
			)->grid(-column => 1, -row => $holderstack[0]->{row}, -sticky => 'ew', -padx => 2, -pady => 2);
			$widg->Put($self->Plugin->ConfigGet($key));
			$options{$key} = $widg;
			$holderstack[0]->{row} ++;
		}
	}
	$self->{OPTIONS} = \%options;

	my $b = $self->Subwidget('buttonframe')->Button(
		-text => 'Apply',
		-command => ['ApplyPressed', $self], 
	);
	$self->ButtonPack($b);
	$self->Advertise(Apply => $b);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
	$self->after(1, [AutoUpdate => $self]);
}

sub ApplyPressed {
	my $self = shift;
	my $options = $self->{OPTIONS};
	my @opts = sort keys %$options;
	for (@opts) {
		my $val = $options->{$_}->Get;
		$self->Plugin->ConfigPut($_, $val) if $val ne '';
	}
	$self->Plugin->ReConfigureAll;
	$self->Plugin->SaveSettings(@opts);
}

sub AutoUpdate {
	my $self = shift;
	unless ($self->Pressed) {
		my $options = $self->{OPTIONS};
		my $error = 0;
		for (keys %$options) {
			my $widg = $options->{$_};
			unless ($widg->Validate) {
				$error = 1;
			}
			$widg->EntryUpdate;
		}
		my $b = $self->Subwidget('Apply');
		if ($error) {
			$b->configure(-state => 'disabled');
		} else {
			$b->configure(-state => 'normal');
		}
		$self->after(1000, [AutoUpdate => $self]);
	}
}

sub Holder { return $_[0]->{HOLDERSTACK}->[0] }

1;
