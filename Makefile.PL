use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::PT::PLNbase',
    VERSION_FROM      => 'lib/Lingua/PT/PLNbase.pm', # finds $VERSION
    PREREQ_PM         => {
			  'Lingua::PT::Abbrev' => 0.05,
			  'Test::Pod' => 1.00,
			  'Test::Pod::Coverage' => 0.08,
			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lingua/PT/PLNbase.pm', # retrieve abstract from module
       AUTHOR         => 'Alberto Simoes <ambs@di.uminho.pt>') : ()),
);
