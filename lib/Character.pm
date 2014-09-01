package Character;

use strict;
use warnings;

use base 'Object';

sub new {

    my ( $self, %args ) = @_;

    $args{ 'hp' } = $args{ 'max_hp' };
    $args{ 'ct' } = 0;
    $args{ 'at' } = 0;
    $args{ 'at_queue' } = [];

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

sub roll_ability {

    my ( $self, $ability ) = @_;

    return $ability -> roll();
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

sub at {

    return shift -> accessor( at => @_ );
}

sub schedule_at {

    my ( $self, $cost, $action ) = @_;

    push( @{ $self -> { 'at_queue' } }, [ $cost, $action ] );

    return;
}

sub turn {

    my ( $self ) = @_;

    my $speed = $self -> speed();
    my $new_at = $self -> at() + ( ( $speed < 0 ) ? 0 : $speed );

    $self -> at( ( $new_at > 100 ) ? 100 : $new_at );
    $self -> try_exec_at();
    $self -> ct( 0 );

    return;
}

sub try_exec_at {

    my ( $self ) = @_;

    my $new_at = $self -> at();

    if(
        defined $self -> { 'at_queue' } -> [ 0 ]
        && ( $self -> { 'at_queue' } -> [ 0 ] -> [ 0 ] <= $new_at )
    ) {

        my $at = shift( @{ $self -> { 'at_queue' } } );

        $self -> at( $new_at - $at -> [ 0 ] );

        $at -> [ 1 ] -> ();
    }

    return;
}

sub turns_to_ability {

    my ( $self, $ability ) = @_;

    my $at_deficit = ( $ability -> at() - $self -> at() );
    my $speed = $self -> speed();

    return ( ( $at_deficit > 0 )
        ? ( int( $at_deficit / $speed ) + ( ( $at_deficit % $speed ) ? 1 : 0 ) )
        : 0 );
}

sub max_ability_roll {

    my ( $self, $ability ) = @_;

    return $ability -> max_roll();
}

sub min_ability_roll {

    my ( $self, $ability ) = @_;

    return $ability -> min_roll();
}

1;

__END__
