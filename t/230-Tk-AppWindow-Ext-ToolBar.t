
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::ToolBar'),
};


CreateTestApp(
	-tooliconsize => 32,
	-toolitems => [
		[	'tool_button',		'New',		'poptest',		'document-new',	'Create a new document'], 
		[	'tool_button',		'Open',		'poptest',		'document-open',	'Open a document'],
		[	'tool_separator' ],
		[	'tool_button',		'Save',		'poptest',		'document-save',	'Save current document'], 
		[	'tool_button',		'Close',		'poptest',		'document-close',	'Close current document'], 
	],
	-extensions => [qw[Art ToolBar]],
);

my $plug = $app->GetExt('ToolBar');

@tests = (
	[sub { return $plug->Name eq 'ToolBar' }, 1, 'plugin ToolBar loaded']
);

$app->MainLoop;

