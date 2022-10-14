
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 5;
BEGIN { 
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CBooleanItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CColorItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CFileItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CFloatItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CFolderItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CFontItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CIntegerItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CListItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CRadioItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog::CTextItem');
# 	use_ok('Tk::AppWindow::AWSettingsDialog');
	use_ok('Tk::AppWindow::Plugins::Settings');
};

my $settingsfolder = 't/settings';
my @listvalues = (qw[Top Left Bottom Right North West South East Up Down Far Near]);
my @radiovalues = (qw[Small Medium Large]);

CreateTestApp(
	-configfolder => $settingsfolder,
	-plugins => [qw[Art MenuBar TestPlugin Settings]],
	-useroptions => [
		-set_boolean => ['boolean', 'Boolean test'],
		'*page' => 'Page 1',
		'*section' => 'Section 1',
		-set_color => ['color', 'Color test'],
		-set_list_command => ['list', 'List values test', 'available_icon_themes'],
		-set_file => ['file', 'File test'],
		'*end',
		-set_float => ['float', 'Float test'],
		-set_folder => ['folder', 'Folder test'],
		-set_font => ['font', 'Font test'],
		-set_integer => ['integer', 'Integer test'],
		-set_list_values => ['list', 'List values test', \@listvalues],
		-set_radio_command => ['radio', 'Radio Command test', 'available_icon_sizes'],
		-set_radio_values => ['radio', 'Radio values test', \@radiovalues],
		-set_text => ['text', 'Text test'],
	]
);

my $plug = $app->GetPlugin('Settings');

@tests = (
	[sub { return $plug->Name eq 'Settings' }, 1, 'plugin Settings loaded']
);

$app->MainLoop;

