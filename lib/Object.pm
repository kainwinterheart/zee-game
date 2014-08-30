package Object;

use strict;
use warnings;

sub new {

    my ( $self, %args ) = @_;

    return bless( \%args, ( ref( $self ) || $self ) );
}

sub accessor {

    my ( $self, $key, $val ) = @_;

    if( scalar( @_ ) > 2 ) {

        return $self -> { $key } = $val;

    } else {

        return $self -> { $key };
    }
}

1;

__END__
