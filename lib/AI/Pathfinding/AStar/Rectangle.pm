package AI::Pathfinding::AStar::Rectangle;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use AI::Pathfinding::AStar::Rectangle ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(create_map
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(	
);

our $VERSION = '0.12';

require XSLoader;
XSLoader::load('AI::Pathfinding::AStar::Rectangle', $VERSION);

# Preloaded methods go here.

sub create_map($){
    unshift @_, __PACKAGE__;
    goto &new;
}

1 for ($a, $b); #suppress warnings

sub draw_path{
    my $map  = shift;
    my ($x, $y) = splice @_, 0, 2;
    my $path  = shift;

    my @map;
    $map->foreach_xy( sub {$map[$a][$b]= $_} );

# draw path
    my %vect = (
            #      x  y
            1 => [-1, 1, ], 
            2 => [ 0, 1, '.|'],
            3 => [ 1, 1, '|\\'],
            4 => [-1, 0, '|<'],
            6 => [ 1, 0, '|>'],
            7 => [-1,-1, '|\\'],
            8 => [ 0,-1, '\'|'],
            9 => [ 1,-1, '|/']
    );

    my @path = split //, $path;
    print "Steps: ".scalar(@path)."\n";
    for ( @path )
    {
            $map[$x][$y] = '|o';
            $x += $vect{$_}->[0];
            $y -= $vect{$_}->[1];
            $map[$x][$y] = '|o';
    }

    printf "%02d", $_ for 0 .. $map->last_x;
    print "\n";
    for my $y ( 0 .. $map->last_y - 1 )
    {
            for my $x ( 0 .. $map->last_x - 1 )
            {
                    print $map[$x][$y] eq 
                    '1' ? "|_" : ( 
                    $map[$x][$y] eq '0' ? "|#" : ( 
                    $map[$x][$y] eq '3' ? "|S" : ( 
                    $map[$x][$y] eq '4' ? "|E" : $map[$x][$y] ) ) );
            }
            print "$y\n";
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

AI::Pathfinding::AStar::Rectangle -  AStar search on rectangle map

=head1 SYNOPSIS

  use AI::Pathfinding::AStar::Rectangle qw(create_map);

  my $map = create_map({height=>10, width=>10}); 
  for my $x ($map->start_x..$map->last_x){
      for my $y ($map->start_y..$map->last_y)
          $map->set_value($x, $y, $A[$x][$y]) # 1 - Can pass throu , 0 - Can't
      }
  }
  
  my $path = $map->astar( $from_x, $from_y, $to_x, $to_y);

  print $path, "\n"; # print path in presentation of "12346789" like keys at keyboard


=head1 DESCRIPTION

AI::Pathfinding::AStar::Rectangle provide abstraction for Rectangle map with AStar algoritm

=head1 OBJECT METHODS

=over 4

=item new { "width" => map_width, "height" => map_heigth }

Create AI::Pathfinding::AStar::Rectangle object. Object represent map with given height and width.

=item set_passability  x, y, value # value: 1 - can pass through point, 0 - can't 

Set passability for point(x,y)

=item get_passability (x,y)

Get passability for point

=item astar(from_x, from_y, to_x, to_y)

Search path from one point to other

return path like "1234"

where
1 - mean go left-down
2 - down
3 - down-right 
...
9 - right-up

=item width()

Get map width

=item height()

Get map height

=item start_x(), start_y()

Get/Set coords for leftbottom-most point 

=item last_x(), last_y()

Get coords for right-upper point 

=item foreach_xy( BLOCK )

Call BLOCK for every point on map.

$map->foreach_xy( sub { $A[$a][$b] = $_ }) 
($a, $b, $_) (x, y, passability) 

=item foreach_xy_set( sub { $A[$a][$b] });

 set passability for every point at map. 
 BLOCK must return passability for point ($a, $b);
 $a and  $b must be global var not declared as my, our, 

=item is_path_valid( start_x, start_y, path)

In scalar context return boolean value, 
true - if every point on path is passable, else return false
In list context return 
( end_x, end_y, weigth, true or false )


=item path_goto( start_x, start_y, path)

In list context return 
( end_x, end_y, weigth )

=item draw_path( start_x, start_y, path)

 print path to STDOUT

=head2 EXAMPLES

See ./examples 

=head2 EXPORT

None by default.

=head1 SEE ALSO

=head1 AUTHOR

A.G. Grishaev, E<lt>gtoly@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by A.G. Grishaev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
