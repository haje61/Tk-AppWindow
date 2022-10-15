
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

{
	package TestTextManager;

	use Tk;
	use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
	Construct Tk::Widget 'TestTextManager';
	require Tk::TextUndo;

	sub Populate {
		my ($self,$args) = @_;
		
		$self->SUPER::Populate($args);
		my $text = $self->Scrolled('TextUndo',
		)->pack(-expand => 1, -fill => 'both');
		$self->{T} = $text;

		$self->ConfigSpecs(
			-background => [$text],
			DEFAULT => ['SELF',],
		);
	}
	
	sub doClear {
		my $self = shift;
		my $t = $self->{T};
		$t->delete('0.0', 'end');
		$t->editReset;
	}
	
	sub doLoad {
		my ($self, $file) = @_;
		my $t = $self->{T};
		$self->{T}->Load($file);
		$t->editModified(0);
	}
	
	sub doSave {
		my ($self, $file) = @_;
		my $t = $self->{T};
		$t->Save($file);
		$t->editModified(0);
	}

	sub IsModified {
		my $self = shift;
		return $self->{T}->editModified;	
	}
	
	1;
}

use Test::More tests => 4;
BEGIN { use_ok('Tk::AppWindow::Ext::SDI') };

my $settingsfolder = 't/settings';


CreateTestApp(
	-configfolder => $settingsfolder,
	-extensions => [qw[Art SDI]],
	-contentmanagerclass => 'TestTextManager',
);

my $plug = $app->GetExt('SDI');

@tests = (
	[sub { return $plug->Name eq 'SDI' }, 1, 'plugin SDI loaded']
);

$app->CommandExecute('file_new');
$app->MainLoop;

