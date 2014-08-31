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

    my ( $self, $character_a, $character_b ) = @_;

    my $ability = $character_a -> abilities() -> [ 0 ]; # TODO
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

    my ( $self, $character, $characters ) = @_;

    if( scalar( @$characters ) == 1 ) {

        return $characters -> [ 0 ];
    }

    my $max_damage = undef;
    my %tree = ();

    foreach my $character ( @$characters ) {

        my $l_max_damage = $character -> max_damage();

        if( ! defined $max_damage || ( $l_max_damage >= $max_damage ) ) {

            $max_damage = $l_max_damage;

            push( @{ $tree{ $max_damage } }, $character );
        }
    }

    $characters = $tree{ $max_damage };

    if( scalar( @$characters ) == 1 ) {

        return $characters -> [ 0 ];
    }

    %tree = ();

    my $min_hp = undef;

    foreach my $character ( @$characters ) {

        my $l_min_hp = $character -> hp();

        if( ! defined $min_hp || ( $l_min_hp <= $min_hp ) ) {

            $min_hp = $l_min_hp;

            push( @{ $tree{ $min_hp } }, $character );
        }
    }

    $characters = $tree{ $min_hp };

    if( scalar( @$characters ) == 1 ) {

        return $characters -> [ 0 ];
    }

    %tree = ();

    my $min_distance = undef;

    foreach my $character_b ( @$characters ) {

        my $path = $self -> find_best_path( $character, $character_b );

        next unless defined $path;

        my $l_min_distance = $path -> { 'step' };

        if( ! defined $min_distance || ( $l_min_distance <= $min_distance ) ) {

            $min_distance = $l_min_distance;

            push( @{ $tree{ $min_distance } }, $character_b );
        }
    }

    return undef unless defined $min_distance;

    return $tree{ $min_distance } -> [ 0 ];
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
