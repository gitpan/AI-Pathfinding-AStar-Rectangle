use Test::More 'no_plan';
1 for $Test::More::TODO;
use Data::Dumper;

my $T;

BEGIN{
    $T = "AI::Pathfinding::AStar::Rectangle";
    eval "use ExtUtils::testlib;" unless grep { m/testlib/ } keys %INC;
    eval "use $T";
}

my $m  = $T->new({ width => 5, heigth => 5 });
for my $d ("0".."9"){
    is_deeply([$m->path_valid(0,0,$d)], ['']);
    print Dumper([$m->path_valid(0,0,$d)], ['']);
};

$m->set_start_xy(2,5);

for my $x (2..6){
    for my $y(5..9){
        $m->set_passability($x,$y, 1);
    }
}

is_deeply( [$m->path_valid(2,5, $_)], [''],  "failed from 2,5 path=$_") for split "", 73412;
is_deeply( [scalar $m->path_valid(2,5, $_)], [1],  "success from 2,5 path=$_") for split "", 89605;

is_deeply( [$m->path_valid(2,9, $_)], [''],  "failed from 2,5 path=$_") for split "", 14789;
is_deeply( [scalar $m->path_valid(2,9, $_)], [1],  "success from 2,5 path=$_") for split "", 23605;



is_deeply( [$m->path_valid(6,5, $_)], [''],  "failed from 2,5 path=$_") for split "", 12369;
is_deeply( [scalar $m->path_valid(6,5, $_)], [1],  "success from 2,5 path=$_") for split "", 47805;

is_deeply( [$m->path_valid(6,9, $_)], [''],  "failed from 2,5 path=$_") for split "", 78963;
is_deeply( [scalar $m->path_valid(6,9, $_)], [1],  "success from 2,5 path=$_") for split "", 12405;



is_deeply( [$m->path_valid(3,6, $_)], [3, 6, 20, 1],  "success from 2,5 path=$_") for unpack "(a2)*","46648228" ;
is_deeply( [$m->path_valid(3,6, $_)], [3, 6, 28, 1],  "success from 2,5 path=$_") for unpack "(a2)*","19913773" ;
is_deeply( [$m->path_valid(3,6, $_)], [3, 6, 100, 1],  "success from 2,5 path=$_") for unpack "(a2)*","00550550" ;

for my $x (2..6){
    for my $y(5..9){
        is_deeply( [$m->path_valid($x, $y, "")], [$x, $y, 0, 1],  "success from $x,$y path=''") ;
    }
}

