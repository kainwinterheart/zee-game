package Field;

use strict;
use warnings;

use base 'Object';

use Point ();

sub new {

    my ( $self, %args ) = @_;

    $args{ 'points' } = [];
    $args{ 'points_by_id' } = {};

    return $self -> SUPER::new( %args );
}

sub from_array {

    my ( $self, $array ) = @_;

    $self = $self -> new();

    for( my $y = 0; $y < scalar( @$array ); ++$y ) {

        for( my $x = 0; $x < scalar( @{ $array -> [ $y ] } ); ++$x ) {

            $self -> set( Point -> new(
                x => $x,
                y => $y,
                id => $array -> [ $y ] -> [ $x ],
            ) );
        }
    }

    return $self;
}

sub to_array {

    my ( $self ) = @_;

    my @out = ();

    foreach my $row ( @{ $self -> { 'points' } } ) {

        my @row = ();

        foreach my $col ( @$row ) {

            push( @row, $col -> id() );
        }

        push( @out, \@row );
    }

    return \@out;
}

sub as_string {

    my ( $self ) = @_;

    my $str = '';
    my $len = undef;

    foreach my $row ( @{ $self -> { 'points' } } ) {

        my @row = ();

        foreach my $col ( @$row ) {

            push( @row, $col -> id() );
        }

        $str .= sprintf( "| %s |\n", join( ' ', map( { ( $_ eq '' ) ? '_' : $_ } @row ) ) );
        $len //= length( $str ) - 1;
    }

    $str = ( '-' x $len ) . "\n" . $str . ( '-' x $len ) . "\n";

    return $str;
}

sub set {

    my ( $self, $point ) = @_;

    $self -> { 'points' } -> [ $point -> y() ] -> [ $point -> x() ] = $point;
    $self -> { 'points_by_id' } -> { $point -> id() } = $point;

    return $point;
}

sub swap {

    my ( $self, $point_a, $point_b ) = @_;

    my %h = map( { $_ => $point_a -> $_() } ( 'x', 'y' ) );

    $point_a -> $_( $point_b -> $_() ) for ( 'x', 'y' );
    $point_b -> $_( $h{ $_ } ) for ( 'x', 'y' );

    $self -> set( $_ ) for ( $point_a, $point_b );

    return;
}

sub get_by_coords {

    my ( $self, $x, $y ) = @_;

    return $self -> { 'points' } -> [ $y ] -> [ $x ];
}

sub get_by_id {

    my ( $self, $id ) = @_;

    return $self -> { 'points_by_id' } -> { $id };
}

sub size {

    my ( $self ) = @_;

    my $y = scalar( @{ $self -> { 'points' } } );

    if( $y > 0 ) {

        return ( scalar( @{ $self -> { 'points' } -> [ 0 ] } ), $y );

    } else {

        return ( 0, 0 );
    }
}

sub neighbours {

    my ( $self, $point ) = @_;

    my ( $mx, $my ) = $self -> size();
    my @neighbours = ();

    foreach my $neighbour ( @{ $point -> neighbours() } ) {

        my ( $x, $y ) = @$neighbour;

        if( ( $x >= 0 ) && ( $y >= 0 ) && ( $x < $mx ) && ( $y < $my ) ) {

            push( @neighbours, $self -> get_by_coords( $x, $y ) );
        }
    }

    return \@neighbours;
}

sub empty_point {

    my ( $self, $point ) = @_;

    delete( $self -> { 'points_by_id' } -> { $point -> id() } );

    $point -> id( '' );

    $self -> set( $point );

    return $point;
}

1;

__END__
