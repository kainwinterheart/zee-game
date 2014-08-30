package Path;

use strict;
use warnings;

use base 'Object';

sub find {

    my ( $self, $field, $from, $to ) = @_;

    return undef unless $to -> is_accessible();

    ( $from, $to ) = ( $to, $from );

    my $min = $from -> manhattan_distance( $to );
    my %stack = ( $min => [ { point => $from, next => undef, step => 0 } ] );
    my %seen = ( $from -> num() => 1 );
    my $path = undef;

    while( defined( my $node = shift( @{ $stack{ $min } } ) ) ) {

        foreach my $point ( @{ $field -> neighbours( $node -> { 'point' } ) } ) {

            if( $point -> is( $to ) ) {

                $path = { point => $to, next => $node, step => ( $node -> { 'step' } + 1 ) };

                last;

            } elsif( $point -> is_accessible() && ! exists $seen{ $point -> num() } ) {

                $seen{ $point -> num() } = 1;

                my $key = $point -> manhattan_distance( $to );

                if( $key < $min ) {

                    $min = $key;
                }

                push( @{ $stack{ $key } }, { point => $point, next => $node, step => ( $node -> { 'step' } + 1 ) } );

                @{ $stack{ $key } } = sort( { rand() <=> rand() } @{ $stack{ $key } } );
            }
        }

        last if defined $path;

        if( scalar( @{ $stack{ $min } } ) == 0 ) {

            delete( $stack{ $min } );

            $min = undef;

            while( my ( $key ) = each( %stack ) ) {

                if( defined $min ) {

                    if( $key < $min ) {

                        $min = $key;
                    }

                } else {

                    $min = $key;
                }
            }
        }

        last unless defined $min;
    }

    return $path;
}

1;

__END__
