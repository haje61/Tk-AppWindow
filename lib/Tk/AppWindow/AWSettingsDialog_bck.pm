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
	$self->{HOLDERSTACK} = [$holder];
	
	my $uo = $self->Plugin->ConfigGet('-useroptions');
	my @useroptions = @$uo;
	my %options = ();
	my $row = 0;
	my $notebook;
	
	while (@useroptions) {
		my $key = shift @useroptions;
		my $conf = shift @useroptions;
		if ($key eq 'page') {
			unless (defined $notebook) {
				$notebook = $holder->NoteBook->grid(-column => 0, -columnspan => 2, -sticky => 'nesw');
			}
			$holder = $notebook->add($conf, -label => $conf);
			$holder->gridColumnconfigure(1, -weight => 1);
			$row = 0;
		} else {
			my ($type, $label, $values) = @$conf;
			$holder->Label(-text => $label)->grid(-column => 0, -row => $row, -sticky => 'e', -padx => 2, -pady => 2);
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

			my $widg = $holder->$class(@opts,
				-plugin => $self->Plugin
			)->grid(-column => 1, -row => $row, -sticky => 'ew', -padx => 2, -pady => 2);
			$widg->Put($self->Plugin->ConfigGet($key));
			$options{$key} = $widg;
			$row ++;
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
		DEFAULT => ['SELF'],
	);
	$self->after(1, [AutoUpdate => $self]);
}

sub ApplyPressed {
	my $self = shift;
	my $options = $self->{OPTIONS};
	my @opts = sort keys %$options;
	for (@opts) {
		$self->Plugin->ConfigPut($_, $options->{$_}->Get);
	}
	$self->Plugin->ReConfigure;
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
		$self->after(200, [AutoUpdate => $self]);
	}
}

sub Holder { return $_[0]->{HOLDERSTACK}->[0] }

1;
