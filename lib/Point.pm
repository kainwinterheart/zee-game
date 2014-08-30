package Point;

use strict;
use warnings;

use base 'Object';

{
    my $num = 0;

    sub new {

        my ( $self, %args ) = @_;

        $args{ 'num' } = ++$num;

        return $self -> SUPER::new( %args );
    }
}

sub num {

    return shift -> accessor( num => @_ );
}

sub x {

    return shift -> accessor( x => @_ );
}

sub y {

    return shift -> accessor( y => @_ );
}

sub id {

    return shift -> accessor( id => @_ );
}

sub manhattan_distance {

    my ( $self, $point ) = @_;

    return ( ( abs( $self -> x() - $point -> x() ) + abs( $self -> y() - $point -> y() ) ) / 2 );
}

sub is_accessible {

    my ( $self ) = @_;

    return ( $self -> id() eq '' );
}

sub neighbours {

    my ( $self ) = @_;

    my @source = map( { $self -> $_() } ( 'x', 'y' ) );
    my @neighbours = ();
    my $cnt = scalar( @source );

    foreach my $mod (
        [ 0, 1 ],
        [ 1, 0 ],
        [ 0, -1 ],
        [ -1, 0 ],
    ) {

        my @neighbour = ();

        for( my $i = 0; $i < $cnt; ++$i ) {

            $neighbour[ $i ] = $source[ $i ] + $mod -> [ $i ];
        }

        push( @neighbours, \@neighbour );
    }

    return \@neighbours;
}

sub is {

    my ( $self, $point ) = @_;

    return ( $self -> num() == $point -> num() );
}

1;

__END__
