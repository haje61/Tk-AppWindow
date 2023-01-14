
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::MenuBar') };

CreateTestApp(
	-extensions => [qw[Art MenuBar TestPlugin]],
	-mainmenuitems => [
		[	'menu_check',		'Icons::Check 2',	"Check 1",		'edit-cut',	'-check_1', 'Rotterdam', 'Amsterdam'],
		[  'menu',				undef, 			'~File'],
		[	'menu_normal',		'File::',		"~New",					'file_new',				'document-new',	'Control-n'			], 
		[	'menu_separator',	'File::',		'f1' ], 
		[	'menu_normal',		'File::',		"~Open",					'file_open',			'document-open',	'Control-o'			], 
#  		[	'menu', 				'File::',		"Open ~recent", 		'pop_hist_menu', 	], 
		[	'menu_separator',	'File::', 		'f2'], 
		[	'menu_normal',		'File::',		"~Save",					'file_save',			'document-save',	'Control-s'			], 
		[	'menu_normal',		'File::',		"Save ~as",				'document-save-as',	'file_save_as',	undef				], 
		[	'menu_separator',	'File::',		 'f3'], 
		[	'menu_normal',		'File::',		"~Close",				'file_close',			'document-close',	'Control-O'	], 
		[  'menu',				undef, 				'~Icons'],
		[	'menu_check',		'Icons::',			"Check 2",		'edit-copy',	'-check_2'],
		[	'menu_separator',	'Icons::', 'i1' ], 
		[	'menu_radio_s',		'Icons::',		'Co~lors',	[qw[RED GREEN BLUE]], undef,	'-radio_1'],
		[  'menu',				undef,				'~No Icons'],
		[	'menu_check',		'No Icons::',	 	"Check 3",		undef,	'-check_3'],
		[	'menu_separator',	'No Icons::',	'n1' ], 
		[	'menu_radio_s',	'No Icons::',		'S~easons',		[qw[Winter Spring Summer Autumn]], undef,	'-radio_2'],
		[	'menu_separator',	'No Icons::', 'n2'], 
		[	'menu_radio_s',	'No Icons::',		'Ans~wer',		[qw[Yes No]], undef,	'-radio_3'],
	]
);

my @configs = qw(-check_1 -check_2 -check_3 -radio_1 -radio_2 -radio_3);
my %showitems = ();
my $row = 0;
for (@configs) {
	my $var = '';
	$showitems{$_} = \$var;
	$app->Label(-text => $_, -width => 8)->grid(-row => $row, -column => 0, -padx => 3, -pady => 3);
	$app->Label(-width => 10, -textvariable => \$var)->grid(-row => $row, -column => 1, -padx => 3, -pady => 3);
	$row ++
}


my $plug = $app->GetExt('MenuBar');

@tests = (
	[sub { return $plug->Name eq 'MenuBar' }, 1, 'plugin MenuBar loaded']
);

&Update;
$app->MainLoop;

sub Update {
	for (@configs) {
		my $rvar = $showitems{$_};
		$$rvar = $app->ConfigGet($_); 
	}
	$app->after(200, \&Update);
}
