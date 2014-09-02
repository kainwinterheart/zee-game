package Engine;

use strict;
use warnings;

use base 'Object';

use Path ();

use Time::HiRes ();

sub new {

    my ( $self, %args ) = @_;

    my $players = delete( $args{ 'players' } );

    $args{ 'players' } = [];
    $args{ 'players_by_id' } = {};
    $args{ 'foes' } = {};
    $args{ 'foes_cnt' } = {};

    $self = $self -> SUPER::new( %args );

    if( defined $players ) {

        foreach my $player ( @$players ) {

            $self -> add_player( $player );
        }
    }

    return $self;
}

sub field {

    return shift -> accessor( field => @_ );
}

sub move_character {

    my ( $self, $character, $path ) = @_;

    my $field = $self -> field();
    my $from = $field -> get_by_id( $character -> id() );

    $path = $path -> { 'next' };

    while( defined $path ) {

        $field -> swap( $from, $path -> { 'point' } );

        $path = $path -> { 'next' };

        print $character -> name(), ":\n";
        print $field -> as_string(), "\n";

        Time::HiRes::sleep( 0.5 );
    }

    return;
}

sub find_best_path {

    my ( $self, $ability, $character_a, $character_b ) = @_;

    my $field = $self -> field();
    my $from = $field -> get_by_id( $character_a -> id() );
    my $path = undef;

    my @points = ( $field -> get_by_id( $character_b -> id() ) );

    foreach ( 1 .. ( $ability -> range() + ( $ability -> area() - 1 ) ) ) {

        my @new_points = ();
        my $break = 0;

        foreach my $point ( @points ) {

            if( $point -> is( $from ) ) {

                @points = ( $point );

                $break = 1;

                last;
            }

            push( @new_points, @{ $field -> neighbours( $point ) } );
        }

        last if $break;

        @points = @new_points;
    }

    foreach my $point ( sort( { rand() <=> rand() } @points ) ) {

        if( $point -> is( $from ) ) {

            $path = { step => 0, point => $point, next => undef };

            last;

        } elsif( defined $path ) {

            my $l_path = Path -> find( $field, $from, $point );

            if( defined $l_path && ( $l_path -> { 'step' } < $path -> { 'step' } ) ) {

                $path = $l_path;
            }

        } else {

            $path = Path -> find( $field, $from, $point );
        }
    }

    return undef unless defined $path;

    my $it = $path;

    foreach ( 1 .. $character_a -> max_movement_range() ) {

        $it = $it -> { 'next' };
    }

    delete( $it -> { 'next' } );

    return $path;
}

sub find_best_target {

    my ( $self, $character, $foes ) = @_;

    if( scalar( @$foes ) == 0 ) {

        return undef;
    }

    my $hp = $character -> hp();
    my %tree = ();
    my $field = $self -> field();
    my $ability = $character -> abilities() -> [ 0 ]; # TODO
    my $min_score = undef;
    my $turns_to_ability = $character -> turns_to_ability( $ability );
    my $max_movement_range = $character -> max_movement_range();

    my $max_ability_roll = $character -> max_ability_roll( $ability );
    my $min_ability_roll = $character -> min_ability_roll( $ability );

    my $max_ability_roll_probability = $ability -> max_roll_probability();
    my $avg_ability_roll = ( $min_ability_roll
        + int( ( $max_ability_roll - $min_ability_roll ) / 2 ) );

    foreach my $foe ( @$foes ) {

        my $score = 0;

        my $path = $self -> find_best_path( $ability, $character, $foe );

        next unless defined $path;

        if( $path -> { 'step' } == 0 ) {

            # if character has no need to move to attack

            $score += 0;

        } elsif( $path -> { 'step' } <= $max_movement_range ) {

            # if character will reach attacking position within one turn

            $score += 60;

        } elsif( $max_movement_range > 0 ) {

            # if character will reach attacking position within more than one turn

            $score += 70 * (
                int( $path -> { 'step' } / $max_movement_range )
                + ( ( int( $path -> { 'step' } % $max_movement_range ) ? 1 : 0 ) )
            );

        } else {

            # if character can't move and its foe is too far to strike now

            next;
        }

        my $foe_hp = $foe -> hp();
        my $max_ability_score = undef;

        foreach my $foe_ability ( @{ $foe -> abilities() } ) {

            my $ability_score = 0;
            my $turns_to_foe_ability = $foe -> turns_to_ability( $foe_ability );

            my $foe_max_ability_roll = $foe -> max_ability_roll( $foe_ability );
            my $foe_min_ability_roll = $foe -> min_ability_roll( $foe_ability );

            my $foe_max_ability_roll_probability = $foe_ability -> max_roll_probability();
            my $foe_avg_ability_roll = ( $foe_min_ability_roll
                + int( ( $foe_max_ability_roll - $foe_min_ability_roll ) / 2 ) );

            my $hp_score = 0;

            if( $hp <= $foe_min_ability_roll ) {

                $hp_score = 60;

            } elsif( $hp <= $foe_avg_ability_roll ) {

                $hp_score = 50;

            } elsif( $hp <= $foe_max_ability_roll ) {

                if( $max_ability_roll_probability > $foe_max_ability_roll_probability ) {

                    $hp_score = 30;

                } else {

                    $hp_score = 40;
                }

            } else {

                $hp_score = 20;
            }

            my $turns_modifier = 2;

            if( $turns_to_foe_ability < $turns_to_ability ) {

                $turns_modifier = 1 + 2 * ( $turns_to_foe_ability - $turns_to_ability );

            } elsif( $turns_to_foe_ability > $turns_to_ability ) {

                $turns_modifier = 1;
            }

            if( $foe_hp <= $min_ability_roll ) {

                $ability_score += 0;

            } elsif( $foe_hp <= $avg_ability_roll ) {

                $ability_score += 30;

            } elsif( $foe_hp <= $max_ability_roll ) {

                $ability_score += $hp_score;

            } else {

                $ability_score += 10 + $hp_score;
            }

            $ability_score *= $turns_modifier;

            if( defined $max_ability_score ) {

                if( $ability_score > $max_ability_score ) {

                    $max_ability_score = $ability_score;
                }

            } else {

                $max_ability_score = $ability_score;
            }
        }

        $score += ( $max_ability_score // 0 );

        if( $foe_hp == $foe -> max_hp() ) {

            $score += 30;
        }

        if( defined $min_score ) {

            if( $min_score > $score ) {

                $min_score = $score;
            }

        } else {

            $min_score = $score;
        }

        push( @{ $tree{ $score } }, {
            path => $path,
            character => $foe,
            score => $score,
            ability => $ability,
        } );

        warn $foe -> name(), ' got ', $score, ' for ', $character -> name(), "\n";
    }

    return undef unless defined $min_score;

    return $tree{ $min_score } -> [ int( rand( scalar( @{ $tree{ $min_score } } ) ) ) ];
}

sub add_player {

    my ( $self, $player ) = @_;

    return $player if exists $self -> { 'players_by_id' } -> { $player -> id() };

    push( @{ $self -> { 'players' } }, $player );

    $self -> { 'players_by_id' } -> { $player -> id() } = $#{ $self -> { 'players' } };

    return $player;
}

sub remove_player {

    my ( $self, $player ) = @_;

    my $player_id = $player -> id();
    my $index = $self -> { 'players_by_id' } -> { $player_id };

    splice( @{ $self -> { 'players' } }, $index, 1 );

    foreach my $index ( $index .. $#{ $self -> { 'players' } } ) {

        -- $self -> { 'players_by_id' } -> { $self -> { 'players' } -> [ $index ] -> id() };
    }

    foreach my $foe ( @{ $self -> foes_of( $player ) } ) {

        my $foe_id = $foe -> id();

        delete( $self -> { 'foes' } -> { $foe_id } -> { $player_id } );

        if( -- $self -> { 'foes_cnt' } -> { $foe_id } == 0 ) {

            delete( $self -> { 'foes' } -> { $foe_id } );
            delete( $self -> { 'foes_cnt' } -> { $foe_id } );
        }
    }

    delete( $self -> { 'foes' } -> { $player_id } );
    delete( $self -> { 'foes_cnt' } -> { $player_id } );

    return $player;
}

sub get_player_by_id {

    my ( $self, $id ) = @_;

    return $self -> { 'players' } -> [ $self -> { 'players_by_id' } -> { $id } ];
}

sub foes {

    my ( $self, $player_a, $player_b ) = @_;

    $self -> add_player( $_ ) for ( $player_a, $player_b );

    my $a_id = $player_a -> id();
    my $b_id = $player_b -> id();

    $self -> { 'foes' } -> { $a_id } -> { $b_id } = 1;
    $self -> { 'foes' } -> { $b_id } -> { $a_id } = 1;

    ++ $self -> { 'foes_cnt' } -> { $a_id };
    ++ $self -> { 'foes_cnt' } -> { $b_id };

    return;
}

sub is_foe {

    my ( $self, $player_a, $player_b ) = @_;

    return (
        exists $self -> { 'foes' } -> { $player_a -> id() }
        && exists $self -> { 'foes' } -> { $player_a -> id() } -> { $player_b -> id() }
    );
}

sub foes_of {

    my ( $self, $player ) = @_;

    my @list = ();

    if( exists $self -> { 'foes' } -> { $player -> id() } ) {

        while( my ( $id ) = each( %{ $self -> { 'foes' } -> { $player -> id() } } ) ) {

            push( @list, $self -> get_player_by_id( $id ) );
        }
    }

    return \@list;
}

sub players {

    my ( $self ) = @_;

    return $self -> { 'players' };
}

sub tick {

    my ( $self ) = @_;

    foreach my $player ( @{ $self -> { 'players' } } ) {

        $player -> tick();
    }

    return;
}

sub turn {

    my ( $self ) = @_;

    foreach my $player ( @{ $self -> { 'players' } } ) {

        $player -> turn();
    }

    return;
}

sub get_characters_list {

    my ( $self ) = @_;

    return map( { @{ $_ -> characters() } } grep( { $_ -> is_alive() } @{ $self -> players() } ) );
}

sub total_foes_cnt {

    my ( $self ) = @_;

    my $foes_cnt = 0;

    while( my ( undef, $cnt ) = each( %{ $self -> { 'foes_cnt' } } ) ) {

        $foes_cnt += $cnt;
    }

    return ( $foes_cnt / 2 );
}

sub is_battle_over {

    my ( $self ) = @_;

    return ( $self -> total_foes_cnt() == 0 );
}

1;

__END__
