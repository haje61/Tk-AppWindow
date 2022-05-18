##################################################################################

#First we define a number of handler classes for the types this package can handle

##################################################################################

package CBooleanItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived Tk::Frame);
Construct Tk::Widget 'CBooleanItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	my $var = 0;
	$self->CreateHandler(\$var);

	$self->ConfigSpecs(
		-variable => ['PASSIVE', undef, undef, \$var],
		-errorcolor => ['PASSIVE', 'errorColor', 'ErrorColor', '#ff0000'],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
}

sub CreateHandler {
	my ($self, $var) = @_;
	$self->Checkbutton(
		-onvalue => 1,
		-offvalue => 0,
		-variable => $var,
	)->pack(-side => 'left', -padx => 2);
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
	return 1
}

sub ValidUpdate {
}

##################################################################################
package CColorItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CBooleanItem);
Construct Tk::Widget 'CColorItem';
require Tk::AppWindow::AWColorDialog;

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
	my $entry = $self->Entry(
		-textvariable => $var,
		-width => 8,
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Entry => $entry);
	my $colorview = $self->Label(
		-width => 8,
	)->pack(-side => 'left', -padx => 2, -expand => 1, -fill => 'both');
	$self->Advertise(ColorView => $colorview);

	my $but = $self->Button(
		-command => sub {
			my $dialog = $self->AWColorDialog(
				-title => "Select color",
				-initialcolor => $self->Get,
			);
			my $answer = $dialog->Show(-popover => $self->toplevel);
			if ($answer eq 'Select') {
				$$var = $dialog->Get;
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Select => $but);
}

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 unless defined $var;
	return 1 if $$var eq '';
	return $$var =~ /^#(?:[0-9a-fA-F]{3}){1,4}$/
}

sub ValidUpdate {
	my $self = shift;
	if ($self->Validate) {
		my $var = $self->cget('-variable');
		$self->Subwidget('ColorView')->configure(-background => $$var);
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('ColorView')->configure(-background => $self->cget('-background'));
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-errorcolor'));
	}
}

##################################################################################
package CTextItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CBooleanItem);
Construct Tk::Widget 'CTextItem';

sub Populate {
	my ($self,$args) = @_;

	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		-entryforeground => ['PASSIVE', undef, undef, $self->Subwidget('Entry')->cget('-foreground')],
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

sub ValidUpdate {
	my $self = shift;
	if ($self->Validate) {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-entryforeground'));
	} else {
		$self->Subwidget('Entry')->configure(-foreground => $self->cget('-errorcolor'));
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
	return 1 if $$var eq '';
	return isint $$var unless isfloat $$var;
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
				$$var = $font;
			}
			$dialog->destroy;
		}
	)->pack(-side => 'left', -padx => 2);
	$self->Advertise(Select => $but);
}

##################################################################################
package CIntegerItem;

use strict;
use warnings;
use Tk;
use base qw(Tk::Derived CTextItem);
Construct Tk::Widget 'CIntegerItem';

use Scalar::Util::Numeric qw(isint);

sub Validate {
	my $self = shift;
	my $var = $self->cget('-variable');
	return 1 if $$var eq '';
	return isint $$var
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
	return 1 if $$var eq '';
	return $self->Subwidget('Entry')->Validate
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


##################################################################################

#Now let the party begin

##################################################################################

package Tk::TabbedForm;

use strict;
use warnings;
use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'TabbedForm';


sub Populate {
	my ($self,$args) = @_;

	my $structure = delete $args->{'-structure'};
	$structure = [] unless defined $structure;

	my $colorimage = delete $args->{'-colorimage'};
	$colorimage = $self->Pixmap(-file => Tk->findINC('color_icon.xpm')) unless defined $colorimage;

	my $fileimage = delete $args->{'-fileimage'};
	$fileimage = $self->Pixmap(-file => Tk->findINC('file.xpm')) unless defined $fileimage;

	my $folderimage = delete $args->{'-folderimage'};
	$folderimage = $self->Pixmap(-file => Tk->findINC('folder.xpm')) unless defined $folderimage;
	
	my $fontimage = delete $args->{'-fontimage'};
	$fontimage = $self->Pixmap(-file => Tk->findINC('font_icon.xpm')) unless defined $fontimage;
	
	$self->SUPER::Populate($args);

	my %typeclasses = (
		boolean => {
			class => 'CBooleanItem',
		},
		color => {
			class => 'CColorItem',
			image => $colorimage,
		},
		file => {
			class => 'CFileItem',
			image => $fileimage,
		},
		float => {
			class => 'CFloatItem',
		},
		folder => {
			class => 'CFolderItem',
			image => $folderimage,
		},
		font => {
			class => 'CFontItem',
			image => $fontimage,
		},
		integer => {
			class => 'CIntegerItem',
		},
		list => {
			class => 'CListItem',
		},
		radio => {
			class => 'CRadioItem',
		},
		text => {
			class => 'CTextItem',
		},
	);

	$self->gridColumnconfigure(1, -weight => 1);
	my @holderstack = ({
		holder => $self,
		type => 'root',
		row => 0
	});
	my $notebook;

	my @useroptions = @$structure;
	my $labelwidth = 0;
	while (@useroptions) {
		my $key = shift @useroptions;
		if (($key eq '*page') or ($key eq '*section')) {
			shift @useroptions;
			next;
		}
		if ($key eq '*end') {
			next;
		}
		my $conf = shift @useroptions;
		my $l = length $conf->[1];
		$labelwidth = $l if $l > $labelwidth;
	}

	my %options = ();
	my @padding = (-padx => 2, -pady => 2);

	@useroptions = @$structure;
	while (@useroptions) {
		my $key = shift @useroptions;

		if ($key eq '*page') {
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

		} elsif ($key eq '*section') {
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
			my $conf = shift @useroptions;
			my ($type, $label, $defaultvalue, $values) = @$conf;

			$holderstack[0]->{holder}->Label(-width => $labelwidth, -text => $label, -anchor => 'e')->grid(@padding, -column => 0, -row => $holderstack[0]->{row}, -sticky => 'e');

			my $class = $typeclasses{$type};
			my @opts = ();
			if (exists $class->{'image'}) {
				push @opts, '-image', $class->{'image'}
			}
			use Data::Dumper; print Dumper $values;
			if (defined $values) {
				if ((ref $values) and ($values =~/^ARRAY/)) {
					push @opts, -values => $values;
				} elsif ((ref $values) and ($values =~/^CODE/))  {
					my @vals = &$values;
					push @opts, -values => \@vals;
				} else {
					warn "Value should be list or anonymous sub"
				}
			}

			my $class_name = $class->{'class'};
			my $widg = $holderstack[0]->{holder}->$class_name(@opts,
			)->grid(-column => 1, -row => $holderstack[0]->{row}, -sticky => 'ew', -padx => 2, -pady => 2);
			$widg->Put($defaultvalue) if defined $defaultvalue;
			$options{$key} = $widg;
			$holderstack[0]->{row} ++;
		}
	}
	$self->{OPTIONS} = \%options;

	$self->ConfigSpecs(
		-updatecycle => ['PASSIVE', undef, undef, 1000],
		-autovalidupdate => ['PASSIVE', undef, undef, 1],
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => ['SELF'],
	);
	$self->after(1, sub { $self->AutoValidUpdate($self->cget('-autovalidupdate')) });
}

sub AutoValidUpdate {
	my ($self, $flag) = @_;
	if (defined $flag) {
		if ($flag) {
			my $opt = $self->{OPTIONS};
			for (keys %$opt) { $opt->{$_}->ValidUpdate }
			$self->{AUTOID} = $self->after($self->cget('-updatecycle'), ['AutoValidUpdate', $self, 1]);
		} else {
			if (exists $self->{AUTOID}) {
				$self->afterCancel($self->{AUTOID});
				delete $self->{AUTOID}
			}
		}
	}
	return exists $self->{AUTOID};
}

sub Get {
	my ($self, $key) = @_;
	my $opt = $self->{OPTIONS};
	return $opt->{$key}->Get if (defined $key) and (exists $opt->{$key});
	warn "Invalid key $key" if defined $key;
	my @get = ();
	for (keys %$opt) {
		push @get, $_, $_->Get
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
	return $opt->{$key}->Validate if (defined $key) and (exists $opt->{$key});
	warn "Invalid key $key" if defined $key;
	my $valid = 1;
	for (keys %$opt) { $valid = 0 unless $opt->{$_}->Validate }
	return $valid
}

1;
