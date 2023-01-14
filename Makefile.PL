use ExtUtils::MakeMaker;

WriteMakefile(
	NAME					=> 'Tk::AppWindow',
	VERSION_FROM		=> 'lib/Tk/AppWindow.pm',
	PREREQ_PM			=> {
		'Browser::Open'					=> 0,
		'File::Basename'					=> 0,
		'File::Path'						=> 0,
		'Image::LibRSVG'					=> 0,
# 		'Image::Resize'					=> 0,
		'MIME::Base64'						=> 0,
		'Scalar::Util::Numeric'			=> '0.40',
		'Tk::FontDialog'					=> '0.18',
		'Tk'									=> 0,
		'Tk::GtkSettings'					=> '0.03',
		'Tk::Pod'							=> 0,
	},
	ABSTRACT_FROM		=> 'lib/Tk/AppWindow.pm',
	AUTHOR				=> 'Hans Jeuken <hanje@cpan.org>',
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
          resources => {
              repository => {
                 type => 'git',
		 url  => 'git://github.com/haje61/Tk-AppWindow.git',
                 web  => 'https://github.com/haje61/Tk-AppWindow',
              },
          }})
      : ()
    ),
);

