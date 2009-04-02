use ExtUtils::testlib;
use AI::Pathfinding::AStar::Rectangle;
use Data::Dumper;
use constant WIDTH_X => 64;
use constant WIDTH_Y => 32;


my $m = AI::Pathfinding::AStar::Rectangle->new({ width => WIDTH_X, heigth => WIDTH_Y });
use strict;
use warnings; 
no warnings 'once';

my @from = (0,0);
my @to   = (WIDTH_X >> 1, WIDTH_Y >> 1);
my @map; 
{
#   Generate map 
    for my $x (0 .. WIDTH_X - 1 )
    {
            for my $y (0 .. WIDTH_Y - 1 )
            {
                    $map[$x][$y] = 1;
            }
    }

    $map[5][$_] = 0 for 5 .. WIDTH_Y - 5;
    $map[WIDTH_X - 5][$_] = 0 for 5 .. WIDTH_Y - 5;
    $map[$_][5] = 0 for 5 .. WIDTH_X - 5;
    $map[$_][WIDTH_Y - 5] = 0 for 5 .. WIDTH_X - 10;
    $map[$_][10] = 0 for 10 .. WIDTH_X - 10;
    $map[WIDTH_X - 10][$_] = 0 for 10 .. WIDTH_Y - 5;
    $map[10][$_] = 0 for 10 .. WIDTH_Y - 10;
    $map[$_][WIDTH_Y - 10] = 0 for 10 .. WIDTH_X - 15;
    $map[WIDTH_X - 15][$_] = 0 for 15 .. WIDTH_Y - 10;
    $map[$_][15] = 0 for 15 .. WIDTH_X - 15;
}

# copy map to maap object
$m->foreach_xy_set( sub { $map[$a][$b] });

my ($path) = $m->astar(@to, @from);
sub swap(\@\@){
    @_[0,1] = @_[1,0];;
}
#swap(@to, @from);

$m->draw_path(@to, $path);
