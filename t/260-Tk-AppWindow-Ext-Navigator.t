
use strict;
use warnings;
use lib './t/lib';
use AWTestSuite;

use Test::More tests => 4;
BEGIN { 
	use_ok('Tk::AppWindow::Ext::Navigator');
};

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
		return 1
	}
	
	sub doSave {
		my ($self, $file) = @_;
		my $t = $self->{T};
		$t->Save($file);
		$t->editModified(0);
		return 1
	}

	sub IsModified {
		my $self = shift;
		return $self->{T}->editModified;	
	}
	
	1;
}

CreateTestApp(
	-extensions => [qw[Art Balloon MenuBar ToolBar StatusBar MDI Navigator]],
	-configfolder => $settingsfolder,
	-contentmanagerclass => 'TestTextManager',
);

my $ext = $app->GetExt('Navigator');

@tests = (
	[sub { return $ext->Name eq 'Navigator' }, 1, 'plugin Navigator loaded']
);

$app->MainLoop;

