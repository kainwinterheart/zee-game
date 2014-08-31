package Character;

use strict;
use warnings;

use base 'Object';

sub new {

    my ( $self, %args ) = @_;

    $args{ 'hp' } = $args{ 'max_hp' };
    $args{ 'ct' } = 0;

    return $self -> SUPER::new( %args );
}

sub player {

    return shift -> accessor( player => @_ );
}

sub id {

    return shift -> accessor( id => @_ );
}

sub name {

    return shift -> accessor( name => @_ );
}

sub max_movement_range {

    return shift -> accessor( max_movement_range => @_ );
}

sub max_hp {

    return shift -> accessor( max_hp => @_ );
}

sub hp {

    return shift -> accessor( hp => @_ );
}

sub abilities {

    my ( $self ) = @_;

    return $self -> { 'abilities' };
}

sub damage_hp {

    my ( $self, $damage ) = @_;

    my $new_hp = $self -> hp() - abs( $damage );

    return $self -> hp( ( $new_hp < 0 ) ? 0 : $new_hp );
}

sub gen_damage {

    my ( $self, $ability ) = @_;

    return $ability -> roll();
}

sub max_damage {

    my ( $self ) = @_;

    return $self -> { 'max_damage' } //= do {

        my $damage = 0;

        foreach my $ability ( @{ $self -> abilities() } ) {

            my $l_damage = $ability -> max_roll();

            if( $l_damage > $damage ) {

                $damage = $l_damage;
            }
        }

        ( ( $damage < 0 ) ? 0 : $damage );
    };
}

sub is_alive {

    my ( $self ) = @_;

    return ( $self -> hp() > 0 );
}

sub tick {

    my ( $self ) = @_;

    my $speed = $self -> speed();
    my $new_ct = $self -> ct() + ( ( $speed < 0 ) ? 0 : $speed );

    $self -> ct( ( $new_ct > 100 ) ? 100 : $new_ct );

    return;
}

sub ct {

    return shift -> accessor( ct => @_ );
}

sub is_ready {

    my ( $self ) = @_;

    return ( $self -> ct() == 100 );
}

sub speed {

    return shift -> accessor( speed => @_ );
}



1;

__END__
