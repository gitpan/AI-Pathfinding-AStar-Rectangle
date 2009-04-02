use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless   ($] >= 5.008){
    warn " this perl version not supported $] ";
    exit;
}

WriteMakefile(
    NAME              => 'AI::Pathfinding::AStar::Rectangle',
    VERSION_FROM      => 'lib/AI/Pathfinding/AStar/Rectangle.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/AI/Pathfinding/AStar/Rectangle.pm', # retrieve abstract from module
    AUTHOR         => 'A.G. Grishaev <gtoly@cpan.org>' ,
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
