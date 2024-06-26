package MyLabel;

use strict;
use warnings;

use base qw(Tk::Derived Tk::Label);
Construct Tk::Widget 'MyLabel';

sub Apply {
	print "Apply\n";
}

package main;
use strict;
use warnings;
use lib './t/lib';

use Test::Tk;
$mwclass = 'Tk::AppWindow';

use Test::More tests => 7;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Settings');
};

my $settingsfolder = 't/settings';
my @listvalues = (qw[Top Left Bottom Right North West South East Up Down Far Near]);
my @radiovalues = (qw[Small Medium Large]);

createapp(
	-configfolder => $settingsfolder,
	-extensions => [qw[Art MenuBar TestPlugin Dummy Settings]],
	-useroptions => [
# 		-set_boolean => ['boolean', 'Boolean test'],
		'*page' => 'Page 1',
		'*section' => 'Section 1',
		-set_color => ['color', 'Color test'],
# 		-set_list_command => ['list', 'List values test', 'available_icon_themes'],
		-set_file => ['file', 'File test'],
		'*end',
		'*section' => 'Section 2',
		-set_float => ['float', 'Float test'],
		-set_folder => ['folder', 'Folder test'],
		-set_font => ['font', 'Font test'],
		'*column',
		-set_integer => ['integer', 'Integer test'],
		-set_list_values => ['list', 'List values test', -values => \@listvalues],
# 		-set_radio_command => ['radio', 'Radio Command test', 'available_icon_sizes'],
		-set_radio_values => ['radio', 'Radio values test', -values => \@radiovalues],
		-set_text => ['text', 'Text test'],
		'*end',
	]
);

my $ext;
if (defined $app) {
	$app->geometry('640x400+100+100') if defined $app;
	$ext = $app->extGet('Settings');
}

testaccessors($ext, 'dialog', 'SettingsFile', 'UserOptions');

push @tests,
	[sub { return $ext->Name }, 'Settings', 'extension Settings loaded'],
;

starttesting;



