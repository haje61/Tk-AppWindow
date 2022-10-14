
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 89;
BEGIN { use_ok('Tk::AppWindow::Plugins::Art') };

use Tk::AppWindow;

my @iconpath = ('t/Themes');

my @tests = (
	{
		name => 'Available themes',
		args => [],
		method => 'AvailableThemes',
		expected => [ 'PNG1', 'PNG2', 'SVG1' ]
	},

	# Testing available contexts
	{
		name => 'All available contexts',
		args => ['PNG1' ],
		method => 'AvailableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'Available contexts in name',
		args => ['PNG1', 'edit-cut' ],
		method => 'AvailableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name',
		args => ['PNG1', 'does-not-exist' ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'Available contexts in name and size',
		args => ['PNG1', 'edit-cut', 32 ],
		method => 'AvailableContexts',
		expected => [ 'Actions', ]
	},
	{
		name => 'No available contexts in name and size 1',
		args => ['PNG1', 'does-not-exist', 32 ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'No available contexts in name and size 2',
		args => ['PNG1', 'edit-cut', 45 ],
		method => 'AvailableContexts',
		expected => [ ]
	},
	{
		name => 'Available contexts in size',
		args => ['PNG1', undef, 22 ],
		method => 'AvailableContexts',
		expected => [ 'Actions', 'Applications', ]
	},
	{
		name => 'No available contexts in size',
		args => ['PNG1', undef, 46 ],
		method => 'AvailableContexts',
		expected => [ ]
	},

	# Testing available icons
	{
		name => 'All available icons',
		args => ['PNG1' ],
		method => 'AvailableIcons',
		expected => [ 'accessories-text-editor', 'document-new', 'document-save', 'edit-cut', 'edit-find',
			'help-browser', 'multimedia-volume-control', 'system-file-manager' ]
	},
	{
		name => 'Available icons in size',
		args => ['PNG1', 32 ],
		method => 'AvailableIcons',
		expected => [ 'accessories-text-editor', 'edit-cut', 'edit-find', 'help-browser' ]
	},
	{
		name => 'No available icons in size',
		args => ['PNG1', 47 ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'Available icons in size and context',
		args => ['PNG1', 32, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ 'edit-cut', 'edit-find', ]
	},
	{
		name => 'No available icons in size and context 1',
		args => ['PNG1', 48, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'No available icons in size and context 2',
		args => ['PNG1', 32, 'Blobber' ],
		method => 'AvailableIcons',
		expected => [ ]
	},
	{
		name => 'Available icons in context',
		args => ['PNG1', undef, 'Actions' ],
		method => 'AvailableIcons',
		expected => [ 'document-new', 'document-save', 'edit-cut', 'edit-find' ]
	},
	{
		name => 'No available icons in context',
		args => ['PNG1', undef, 'Blobber' ],
		method => 'AvailableIcons',
		expected => [ ]
	},

	# Testing available sizes
	{
		name => 'All available sizes',
		args => ['PNG1' ],
		method => 'AvailableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'Available sizes in name',
		args => ['PNG1', 'edit-cut'],
		method => 'AvailableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name',
		args => ['PNG1', 'does-not-exist'],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'Available sizes in name and context',
		args => ['PNG1', 'edit-cut', 'Actions'],
		method => 'AvailableSizes',
		expected => [ 32 ]
	},
	{
		name => 'No available sizes in name and context 1',
		args => ['PNG1', 'does-not-exist', 'Actions' ],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'No available sizes in name and context 2',
		args => ['PNG1', 'edit-cut', 'Blobber' ],
		method => 'AvailableSizes',
		expected => [ ]
	},
	{
		name => 'Available sizes in context',
		args => ['PNG1', undef, 'Actions'],
		method => 'AvailableSizes',
		expected => [ 22, 32 ]
	},
	{
		name => 'No available sizes in context',
		args => ['PNG1', undef, 'Blobber'],
		method => 'AvailableSizes',
		expected => [ ]
	},

	# Testing finding icon files
	{
		name => 'Find correct size',
		args => ['document-new', 22, 'Actions' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find incorrect size',
		args => ['document-new', 32, 'Actions' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find incorrect context',
		args => ['document-new', 22, 'Applications' ],
		method => 'FindImage',
		expected => [ 't/Themes/PNG1/actions/22/document-new.png' ]
	},
	{
		name => 'Find nothing',
		args => ['no-exist', 22, 'Applications' ],
		method => 'FindImage',
		expected => [ undef ]
	},


);



my $app = new Tk::AppWindow(
	-plugins => ['Art'],
	-iconpath => \@iconpath,
	-icontheme =>  'PNG1',
);
ok(defined $app, "can create");
$app->after(10, \&DoTesting);

my $art = $app->GetPlugin('Art');

# More tests for loading bitmapped icons
my @names = $art->AvailableIcons('PNG1');
my @sizes = $art->AvailableSizes('PNG1');
&CreateImageTests(\@names, \@sizes, {
	theme => 'PNG1',
	validate => 'image',
});

# Tests for loading svg icons
my @svgnames = $art->AvailableIcons('SVG1');
use Data::Dumper; print Dumper \@svgnames;
my @svgsizes = $art->AvailableSizes('SVG1');
&CreateImageTests(\@svgnames, \@svgsizes, {
	theme => 'SVG1',
	validate => 'image',
	is_svg => 1,
});

$app->MainLoop;

sub DoTesting {
	ok(1, "main loop runs");
	ok(($art->Name eq 'Art'), 'plugin Art loaded');
	for (@tests) {
		if (exists $_->{theme}) {
			$art->ConfigPut(-icontheme => $_->{theme})
		}
		my $checksize;
		if (exists $_->{checksize}) {
			$checksize = $_->{checksize}
		}
		my $args = $_->{args};
		my $expected = $_->{expected};
		my $is_svg = 0;
		if (exists $_->{is_svg}) {
			$is_svg = $_->{is_svg}
		}
		my $method = $art->can($_->{method});
		my $name = $_->{name};
		my $validate = 'list';
		if (exists $_->{validate}) {
			$validate = $_->{validate}
		}
		my @result = &$method($art, @$args);
		if ($validate eq 'list') {
			ok(ListCompare($expected, \@result), $name);
		} elsif ($validate eq 'image') {
			my $img = $result[0];
			my $outcome = 0;
			if (defined $img) { $outcome = 1 }
			is ($outcome, $expected, $name);
			if (defined $checksize) {
				SKIP: {
					skip 'Previous test returned no image.', 1 unless $outcome;
					ok((($img->height eq $checksize) and ($img->width eq $checksize)), 'Check size');
				}
			}
		} else {
			ok(&$validate($expected, \@result), $name);
		}
	}
	if  ($show) {
		my @icons = ();
		my $th = $app->ConfigGet('-iconthemes');
		for (@$th) {
			push @icons, $art->AvailableIcons($_)
		}
		my $maxcol =  4;
		my $col = 0;
		my $row = 0;
		for (@icons) {
			my $lab = $app->Label(
				-image => $art->GetIcon($_, 32),
			)->grid(
				-column => $col,
				-row => $row,
				-padx => 2,
				-pady => 2,
			);
			$col ++;
			if ($col eq 4) {
				$col = 0;
				$row ++
			}
		}
	} else {
		$app->CommandExecute('quit')
	}
}

sub CreateImageTests {
	my ($nms, $szs, $empty) = @_;
	for (@$nms) {
		my $name = $_;
		for (@$szs) {
			my $size = $_;
			my %test = %$empty;
			$test{name} = "GetIcon, $name, $size";
			$test{checksize} = $size;
			$test{method} = 'GetIcon';
			$test{args} = [ $name, $size ];
			$test{expected} = 1;
			$test{validate} = 'image';
			push @tests, \%test;
		}
	}
}


