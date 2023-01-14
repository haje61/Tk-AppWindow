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
	$self->after(1, ['Validate', $self]);
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

=head1 NAME

Tk::TabbedForm - NoteBook based form editor

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';

use Tk;
use base qw(Tk::Frame);
Construct Tk::Widget 'TabbedForm';

require Tk::LabFrame;
require Tk::NoteBook;

=head1 SYNOPSIS

=over 4

 require Tk::TabbedForm;
 my $tree= $window->TabbedForm(@options)->pack;
 $tree->CreateForm;

=back

=head1 DESCRIPTION

=over 4

=back

=head1 B<CONFIG VARIABLES>

=over 4

=item Switch: B<-acceptempty>

=over 4

Default value 0. If set the Validate method will not trigger on
fields containing empty strings.

=back

=item B<-autovalidate>

=over 4

Validate the form whenever an entry changes value.

=back

=item B<-colorimage>

=over 4

Set an image object for I<color> items

=back

=item B<-fileimage>

=over 4

Set an image object for I<file> items

=back

=item B<-folderimage>

=over 4

Set an image object for I<folder> items

=back


=item B<-fontimage>

=over 4

Set an image object for I<folder> items

=back


=item B<-postvalidatecall>

=over 4

Set this callback if you want to take action on the validation result.

=back


=item B<-structure>

=over 4

You have to set this option. Only available at create time.
Example:

[
    -set_boolean => ['boolean', 'Boolean test'],
    '*page' => 'Page 1',
    '*section' => 'Section 1',
    -set_color => ['color', 'Color test'],
    -set_list_command => ['list', 'List values test', sub { return @listvalues } ],
    -set_file => ['file', 'File test'],
    '*end',
    -set_float => ['float', 'Float test'],
    -set_folder => ['folder', 'Folder test'],
    -set_font => ['font', 'Font test'],
    -set_integer => ['integer', 'Integer test'],
    -set_list_values => ['list', 'List values test', \@listvalues],
    -set_radio_command => ['radio', 'Radio Command test', sub { return @radiovalues }],
    -set_radio_values => ['radio', 'Radio values test', \@radiovalues],
    -set_text => ['text', 'Text test'],
 ]

See below.

=back

=back

=head1 THE STRUCTURE OPTION

=over 4

The I<-structure> option is a list that basically looks like:

 [
    $switch => $option,
    $key => [$type, $label, @options],
    ...
 ]


B<SWITCHES>

$switch can have the following values:

=item B<*page>

=over 4

Creates a new page with the name $option.

=back

=item B<*section>

=over 4

Creates a new section with the name $option.

=back

=item B<*section>

=over 4

Creates a new section with the name $option.
You can create nested sections.

=back

=item B<*end>

=over 4

Ends current section.

=back

B<TYPES>

$type can have the following values:

=item B<boolean>

=over 4

 myswitch => ['boolean', 'My switch'],

Creates a Checkbutton item.

=back

=item B<color>

=over 4

mycolor => ['color', 'My color'],

Creates an Entry item with a color label and a button initiating a color dialog.

=back

=item B<file>

=over 4

 myfile => ['file', 'My file'],

Creates an Entry item with a button initiating a file dialog.

=back

=item B<float>

=over 4

 myfloat => ['float', 'My float'],

Creates an Entry item that validates a floating value.

=back

=item B<folder>

=over 4

 mydir => ['folder', 'My folder'],

Creates an Entry item with a button initiating a folder dialog.

=back

=item B<font>

=over 4

 myfont => ['font', 'My font'],

Creates an Entry item with a button initiating a font dialog.

=back

=item B<integer>

=over 4

 myinteger => ['integer', 'My integer'],

Creates an Entry item that validates an integer value.

=back

=item B<list>

=over 4

 mylist => ['list', 'My list', \@values],
 mylist => ['list', 'My list', sub { return @values }],

Creates a ListEntry item.

=back

=item B<radio>

=over 4

 myradio => ['radio', 'My radio', \@values],
 myradio => ['radio', 'My radio', sub { return @values }],

Creates a line of radiobuttons.

=back

=item B<text>

=over 4

 mytext => ['text', 'My text'],

Creates an Entry item.

=back

=back

=cut

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

	my $col_icon = $self->Pixmap(-file => Tk->findINC('color_icon.xpm'));
	my $fil_icon = $self->Pixmap(-file => Tk->findINC('file.xpm'));
	my $dir_icon = $self->Pixmap(-file => Tk->findINC('folder.xpm'));
	my $fon_icon = $self->Pixmap(-file => Tk->findINC('font_icon.xpm'));
	
	$self->ConfigSpecs(
		-acceptempty => ['PASSIVE', undef, undef, 0],
		-autovalidate => ['PASSIVE', undef, undef, 1],
		-background => ['SELF', 'DESCENDANTS'],
		-colorimage => ['PASSIVE', undef, undef, $col_icon],
		-fileimage => ['PASSIVE', undef, undef, $fil_icon],
		-folderimage => ['PASSIVE', undef, undef, $dir_icon],
		-fontimage => ['PASSIVE', undef, undef, $fon_icon],
		-listcall => ['CALLBACK', undef, undef, sub {}],
		-postvalidatecall => ['CALLBACK', undef, undef, sub {}],
		-structure => ['PASSIVE', undef, undef, []],
		DEFAULT => ['SELF'],
	);
}

=head1 METHODS

=over 4

=item B<CreateForm>

=over 4

Call this method after you created the B<Tk::TabbedForm> widget.
It will create all the pages, sections and entries.

=back

=cut

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

=item B<Get>I<(?$key?)>

=over 4

Returns the value of $key. $key is the name of the item in the form.
Returns a hash with all values if $key is not specified.

=back

=cut

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

=item B<Put>(%values)

=over 4

Sets the values in the tabbed form

=back

=cut

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

=item B<Validate>

=over 4

Validates all entries in the form and returns true if
all successfull.

=back

=cut

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
