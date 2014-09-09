package Game;

use strict;
use warnings;

use base 'Object';

sub engine {

    return shift -> accessor( engine => @_ );
}

sub main {

    my ( $self ) = @_;

    my $engine = $self -> engine();
    my $field = $engine -> field();

    print $field -> as_string(), "\n";

    sleep( 1 );

    my @characters = $engine -> get_characters_list();
    my $round = 0;

    while( 1 ) {

        $engine -> tick();

        my %tree = ();

        foreach my $character ( grep( { $_ -> is_ready() } @characters ) ) {

            push( @{ $tree{ $character -> speed() } }, $character );
        }

        my $refresh_characters_list = 0;
        my $active_characters = 0;
        my $moved_characters = 0;

        foreach my $key ( sort( { $b <=> $a } keys( %tree ) ) ) {

            @{ $tree{ $key } } = sort( { rand() <=> rand() } @{ $tree{ $key } } );

            while( defined( my $character = shift( @{ $tree{ $key } } ) ) ) {

                next unless $character -> is_alive();

                ++ $active_characters;

                my @foes = map( { @{ $_ -> characters() } }
                    @{ $engine -> foes_of( $character -> player() ) } );

                next unless scalar( @foes ) > 0;

                my $best_target = $engine -> choose_action( $character, \@foes );
                my $best_path = $best_target -> { 'path' } if defined $best_target;

                if( defined $best_path ) {

                    ++ $moved_characters;

                    $engine -> move_character( $character, $best_path );

                    if( $best_path -> { 'step' } <= $character -> max_movement_range() ) {

                        my $score = $best_target -> { 'score' };
                        my $ability = $best_target -> { 'ability' };
                        $best_target = $best_target -> { 'character' };

                        $character -> schedule_at( $ability -> at() => sub {

                            my $damage = $character -> roll_ability( $ability );

                            $best_target -> damage_hp( $damage );

                            print $character -> name(), ' dealt ', $damage, ' damage to ',
                                $best_target -> name(), ' using ', $ability -> name(),
                                ' (score: ', $score, ')', "\n";

                            unless( $best_target -> is_alive() ) {

                                print $best_target -> name(), ' killed by ', $character -> name(), "\n";

                                my $player = $best_target -> player();

                                $player -> remove_character( $best_target );

                                $field -> empty_point( $field -> get_by_id( $best_target -> id() ) );

                                unless( $player -> is_alive() ) {

                                    $engine -> remove_player( $player );
                                }

                                $refresh_characters_list = 1;
                            }
                        } );
                    }
                }

                $character -> turn();
            }
        }

        last if ( $active_characters > 0 ) && ( $moved_characters == 0 );

        if( $active_characters > 0 ) {

            print 'End of round ', ++$round, "\n";
        }

        if( $refresh_characters_list ) {

            last if $engine -> is_battle_over();

            @characters = $engine -> get_characters_list();
        }
    }

    print $field -> as_string(), "\n";

    return;
}

1;

__END__
