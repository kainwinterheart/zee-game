#!/usr/bin/perl -w

use strict;
use warnings;

use FindBin '$Bin';
use lib "${Bin}/lib";

package main;

use Game ();
use Field ();
use Engine ();
use Player ();
use Character ();
use Ability::Remote::Attacking ();

my $field = Field -> from_array( [
    [ 'a', '', '', '', 'c', ],
    [ '', '', '', '', '', ],
    [ '', '', 'X', '', '', ],
    [ '', '', '', '', '', ],
    [ 'd', '', '', '', 'b', ],
] );

my $melee_attack = Ability::Remote::Attacking -> new(
    name => 'Basic melee attack',
    range => 1,
    area => 1,
    dice => [
        [ 6, 0 ],
    ],
    at => 0,
);

my $character_a = Character -> new(
    id => 'a',
    name => 'First',
    max_movement_range => 1,
    max_hp => 24,
    speed => 1,
    abilities => [
        $melee_attack,
    ]
);

my $character_b = Character -> new(
    id => 'b',
    name => 'Second',
    max_movement_range => 1,
    max_hp => 24,
    speed => 1,
    abilities => [
        $melee_attack,
    ]
);

my $character_c = Character -> new(
    id => 'c',
    name => 'Third',
    max_movement_range => 1,
    max_hp => 24,
    speed => 1,
    abilities => [
        $melee_attack,
    ]
);

my $character_d = Character -> new(
    id => 'd',
    name => 'Fourth',
    max_movement_range => 1,
    max_hp => 24,
    speed => 1,
    abilities => [
        $melee_attack,
    ]
);

my $player_a = Player -> new(
    name => 'Good',
    id => 1,
    characters => [
        $character_a,
        $character_d,
    ]
);

my $player_b = Player -> new(
    name => 'Bad',
    id => 2,
    characters => [
        $character_b,
        $character_c,
    ]
);

my $engine = Engine -> new(
    field => $field,
    players => [
        $player_a,
        $player_b,
    ]
);

$engine -> foes( $player_a, $player_b );

Game -> new( engine => $engine ) -> main();

exit 0;

__END__
