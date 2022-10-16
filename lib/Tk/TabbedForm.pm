##################################################################################

#First we define a number of handler classes for the types this package can handle

##################################################################################

package CTextItem;

use strict;
use warnings;
use base qw(Tk::Derived Tk::Frame);
use Tie::Watch;
Construct Tk::Widget 'CTextItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	my $var = '';
	Tie::Watch->new(
		-variable => \$var,
		-store => sub {
			my ($watch, $value) = @_;
			$watch->Store($value);
			$self->Callback('-validatecall');
		},
	);
	$self->CreateHandler(\$var);

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		-entryforeground => ['PASSIVE', undef, undef, $self->cget('-foreground')],
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#ff0000'],
		-regex => ['PASSIVE', undef, undef, '.*'],
		-validatecall => ['CALLBACK', undef, undef, sub {}],
		-variable => ['PASSIVE', undef, undef, \$var],
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $e = $self->Entry(
		-textvariable => $var,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub Get {
	my $self = shift;
	my $var = $self->cget('-variable');
	return $$var;
}

sub Put {
	my ($self, $value) = @_;
	my $var = $self->cget('-variable');
	$$var = $value;
}

sub Validate {
	my ($self, $val) = @_;
	my $var = $self->cget('-variable');
	return 1 unless defined $var;
	$val = $$var unless defined $val;
	my $reg = $self->cget('-regex');
	my $flag = $val =~ /$reg/;
	$self->ValidUpdate($flag, $val);
	return $flag;
}

sub ValidUpdate {
	my ($self, $flag) = @_;
	unless (defined $self->cget('-entryforeground')) {
		$self->configure(-entryforeground => $self->Subwidget('Entry')->cget('-foreground'));
	}
	if ($flag) {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-errorcolor'));
	}
}

##################################################################################
package CBooleanItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CBooleanItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => [$self->Subwidget('Check')],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $c = $self->Checkbutton(
		-variable => $var,
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Check => $c);
}


sub ValidUpdate {
	my $self = shift
}

##################################################################################
package CColorItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CColorItem';
require Tk::YAColorDialog;

sub Populate {
	my ($self,$args) = @_;
	$args->{'-regex'} = '^#(?:[0-9a-fA-F]{3}){1,4}$';
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-image => [$self->Subwidget('Select')],
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my $self = shift;
	$self->SUPER::CreateHandler(@_);
	my $colorview = $self->Label(
		-width => 4,
	)->pack(-side => 'left', -padx => 2, -fill => 'y');
	$self->Advertise(ColorView => $colorview);

	my $but = $self->Button(
		-command => sub {
			my $dialog = $self->YAColorDialog(
				-title => "Select color",
				-initialcolor => $self->Get,
			);
			my $answer = $dialog->Show(-popover => $self->toplevel);
			if ($answer eq 'Select') {
				$self->Put($dialog->Get);
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Select => $but);
}

sub ValidUpdate {
	my ($self, $flag, $val) = @_;
	$self->SUPER::ValidUpdate($flag);
	if ($flag) {
		$self->Subwidget('ColorView')->configure(-background => $val) unless $val eq '';
	} else {
		$self->Subwidget('ColorView')->configure(-background => $self->cget('-background'));
	}
}

##################################################################################
package CFileItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CFileItem';

sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-image => [$self->Subwidget('Select')],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
}
sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	my $b = $self->Button(
		-command => sub {
			my $file = $self->getOpenFile(
# 				-initialdir => $initdir,
				-popover => 'mainwindow',
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$self->Advertise(Select => $b);
}

##################################################################################
package CFloatItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CFloatItem';

use Scalar::Util::Numeric qw(isfloat isint);

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	my $flag = 0;
	$flag = 1 if $$var eq '';
	$flag = 1 if isint $$var;
	$flag = 1 if isfloat $$var;
	$self->ValidUpdate($flag);
	return 1
}

##################################################################################
package CFolderItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CFileItem);
Construct Tk::Widget 'CFolderItem';

sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	$self->Subwidget('Select')->configure(
		-command => sub {
			my $file = $self->chooseDirectory(
# 				-initialdir => $initdir,
				-popover => $self->toplevel,
			);
			if (defined $file) {
				my $var = $self->cget('-variable');
				$$var = $file
			}
		}
	);
}

##################################################################################
package CFontItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CFontItem';
require Tk::FontDialog;


sub Populate {
	my ($self,$args) = @_;
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-image => [$self->Subwidget('Select')],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	$self->SUPER::CreateHandler($var);
	my @bopt = ();
	my $but = $self->Button(@bopt,
		-command => sub {
			my $dialog = $self->FontDialog(
				-title => "Select font",
				-initfont => $$var,
			);
			my $font = $dialog->Show(-popover => $self->toplevel);
			if (defined $font) {
				$$var =  $dialog->GetDescriptiveFontName($font)
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Select => $but);
}

##################################################################################
package CListItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CListItem';

require Tk::ListEntry;

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	my $e = $self->ListEntry(
		-textvariable => $var,
		-values => $values,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'x');
	$self->Advertise(Entry => $e);
}

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	my $flag = $self->Subwidget('Entry')->Validate;
	$self->ValidUpdate($flag);
	return $flag
}

##################################################################################
package CRadioItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CBooleanItem);
Construct Tk::Widget 'CRadioItem';

sub Populate {
	my ($self,$args) = @_;

	my $values = delete $args->{'-values'};
	warn "You need to set the -values option" unless defined $values;
	$self->{VALUES} = $values;

	$self->SUPER::Populate($args);

	
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	my $values = $self->{VALUES};
	for (@$values) {
		$self->Radiobutton(
			-text => $_,
			-value => $_,
			-variable => $var,
		)->pack(-side => 'left', -padx => 2, -pady => 2);
	}
}

sub ValidUpdate {}

##################################################################################

#Now let the party begin

##################################################################################

package Tk::TabbedForm;

use strict;
use warnings;
use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'TabbedForm';

require Tk::LabFrame;
require Tk::NoteBook;

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	

	$self->{TYPES} = {
		boolean => ['CBooleanItem', -onvalue => 1, -offvalue => 0],
		color => ['CColorItem', -image => '-colorimage'],
		file => ['CFileItem', -image => '-fileimage'],
		float => ['CFloatItem', ],
		folder => ['CFolderItem', -image => '-folderimage'],
		font => ['CFontItem', -image => '-fontimage'],
		'integer' => ['CTextItem', -regex => '^-?\d+$'],
		list => ['CListItem'],
		radio => ['CRadioItem'],
		text => ['CTextItem'],
	};

	$self->gridColumnconfigure(1, -weight => 1);

	$self->ConfigSpecs(
		-acceptempty => ['PASSIVE', undef, undef, 0],
		-autovalidate => ['PASSIVE', undef, undef, 1],
		-background => ['SELF', 'DESCENDANTS'],
		-colorimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('color_icon.xpm'))],
		-fileimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('file.xpm'))],
		-folderimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('folder.xpm'))],
		-fontimage => ['PASSIVE', undef, undef, $self->Pixmap(-file => Tk->findINC('font_icon.xpm'))],
		-listcall => ['CALLBACK', undef, undef, sub {}],
		-postvalidatecall => ['CALLBACK', undef, undef, sub {}],
		-structure => ['PASSIVE', undef, undef, []],
		DEFAULT => ['SELF'],
	);
}

sub CreateForm {
	my $self = shift;
	my @holderstack = ({
		holder => $self,
		type => 'root',
		row => 0
	});
	my $notebook;

	my $structure = $self->cget('-structure');
	my @options = @$structure;
	my $labelwidth = 0;
	while (@options) {
		my $key = shift @options;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @options;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		my $conf = shift @options;
		my $l = length $conf->[1];
		$labelwidth = $l if $l > $labelwidth;
	}

	my %options = ();
	my @padding = (-padx => 2, -pady => 2);

	@options = @$structure;
	while (@options) {
		my $key = shift @options;

		if ($key eq '*page') {
			my $label = shift @options;
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

		} elsif ($key eq '*section') {
			my $label = shift @options;
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
			
		} elsif ($key eq '*end') {
			if ($holderstack[0]->{type} eq 'page') {
				$notebook = undef
			}
			if  (@holderstack > 1) {
				shift @holderstack
			} else {
				warn "Holder stack is already empty"
			}
		} else {
			my $conf = shift @options;
			my ($type, $label, $values) = @$conf;

			$holderstack[0]->{holder}->Label(-width => $labelwidth, -text => $label, -anchor => 'e')->grid(@padding, -column => 0, -row => $holderstack[0]->{row}, -sticky => 'e');

			my $t = $self->{TYPES}->{$type};
			my @o = @$t;
			my $class = shift @o;
			my %opts = (@o,
				-validatecall => ['Validate', $self]
			);
			if ((exists $opts{'-image'}) and ($opts{'-image'} =~ /^-/)) {
				$opts{'-image'} = $self->cget($opts{'-image'})
			}

			if (defined $values) {
				if ((ref $values) and ($values =~/^ARRAY/)) {
					$opts{'-values'} = $values;
				} elsif ((ref $values) and ($values =~/^CODE/))  {
					my @vals = &$values;
					$opts{'-values'} = \@vals;
				} else {
					my @vals = $self->Callback('-listcall', $values);
					$opts{'-values'} = \@vals;
				}
			}

			my $widg = $holderstack[0]->{holder}->$class(%opts,
			)->grid(-column => 1, -row => $holderstack[0]->{row}, -sticky => 'ew', -padx => 2, -pady => 2);
			$options{$key} = $widg;
			$holderstack[0]->{row} ++;
		}
	}
	$self->{OPTIONS} = \%options;
	$self->Validate;
}

sub DefineTypes {
	my $self = shift;
	while (@_) {
		my $type = shift;
		my $conf = shift;
		$self->{TYPES}->{$type} = $conf;
	}
}

sub Get {
	my ($self, $key) = @_;
	my $opt = $self->{OPTIONS};
	return $opt->{$key}->Get if (defined $key) and (exists $opt->{$key});
	warn "Invalid key $key" if defined $key;
	my @get = ();
	for (keys %$opt) {
		push @get, $_, $opt->{$_}->Get
	}
	return @get
}

sub Put {
	my $self = shift;
	my $opt = $self->{OPTIONS};
	while (@_) {
		my $key = shift;
		my $value = shift;
		if (exists $opt->{$key}) {
			$opt->{$key}->Put($value)
		} else {
			warn "Invalid key $key"
		}
	}
}

sub Validate {
	my ($self, $key) = @_;
	my $opt = $self->{OPTIONS};
# 	return $opt->{$key}->Validate if (defined $key) and (exists $opt->{$key});
# 	warn "Invalid key $key" if defined $key;
	my $valid = 1;
	for (keys %$opt) {
		next if ($self->cget('-acceptempty') and ($opt->{$_}->Get eq ''));
		$valid = 0 unless $opt->{$_}->Validate;
	}
	$self->Callback('-postvalidatecall', $valid);
	return $valid
}

1;
