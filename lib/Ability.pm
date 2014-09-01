package Ability;

use strict;
use warnings;

use base 'Object';

sub name {

    return shift -> accessor( name => @_ );
}

sub dice {

    return shift -> accessor( dice => @_ );
}

sub roll {

    my ( $self ) = @_;

    my $amount = 0;

    foreach my $dice ( @{ $self -> dice() } ) {

        $amount += 1 + int( rand( $dice -> [ 0 ] ) ) + $dice -> [ 1 ];
    }

    return ( ( $amount < 0 ) ? 0 : $amount );
}

sub max_roll {

    my ( $self ) = @_;

    return $self -> { 'max_roll' } //= do {

        my $amount = 0;

        foreach my $dice ( @{ $self -> dice() } ) {

            $amount += $dice -> [ 0 ] + $dice -> [ 1 ];
        }

        ( ( $amount < 0 ) ? 0 : $amount );
    };
}

sub at {

    return shift -> accessor( at => @_ );
}

sub max_roll_probability {

    my ( $self ) = @_;

    return $self -> { 'max_roll_probability' } //= do {

        my $cnt = 0;
        my $product = 1;

        foreach my $dice ( @{ $self -> dice() } ) {

            $product *= $dice -> [ 0 ];

            ++$cnt;
        }

        ( ( $cnt > 0 ) ? ( $product / $cnt ) : 0 );
    };
}

sub min_roll {

    my ( $self ) = @_;

    return $self -> { 'min_roll' } //= do {

        my $amount = 0;

        foreach my $dice ( @{ $self -> dice() } ) {

            $amount += 1 + $dice -> [ 1 ];
        }

        ( ( $amount < 0 ) ? 0 : $amount );
    };
}

1

__END__
