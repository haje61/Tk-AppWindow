use ExtUtils::MakeMaker;

use strict;
use Config;
my $osname = $Config{'osname'};

my %prereq = (
	'Browser::Open'					=> '0.04',
	'File::Basename'					=> '2.86',
	'File::Path'						=> '2.18',
	'Imager'								=> '1.019',
	'Imager::File::PNG'				=> '0.99',
	'MIME::Base64'						=> '3.16',
	'Scalar::Util'						=> '1.63',
	'Scalar::Util::Numeric'			=> '0.40',
	'Test::Tk'							=> '3.01',
	'Tk'									=> '804.023',
	'Tk::DocumentTree'				=> '0.02',
	'Tk::FontDialog'					=> '0.18',
	'Tk::GtkSettings'					=> '0.03',
	'Tk::Pod'							=> '5.41',
	'Tk::QuickForm'					=> '0.03',
	'Tk::YADialog'						=> '0.03',
	'Tk::YANoteBook'					=> '0.03',
);
$prereq{'Image::LibRSVG'} = '0.07' unless $osname eq 'MSWin32';

WriteMakefile(
	NAME					=> 'Tk::AppWindow',
	VERSION_FROM		=> 'lib/Tk/AppWindow.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/Tk/AppWindow.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/Tk-AppWindow.git',
            web  => 'https://github.com/haje61/Tk-AppWindow',
         },
      }}
    ) : () ),
);

