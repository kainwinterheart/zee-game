package Player;

use strict;
use warnings;

use base 'Object';

use Scalar::Util 'weaken';

sub new {

    my ( $self, %args ) = @_;

    my $characters = delete( $args{ 'characters' } );

    $args{ 'characters' } = [];
    $args{ 'characters_by_id' } = {};

    $self = $self -> SUPER::new( %args );

    if( defined $characters ) {

        foreach my $character ( @$characters ) {

            $self -> add_character( $character );
        }
    }

    return $self;
}

sub add_character {

    my ( $self, $character ) = @_;

    push( @{ $self -> { 'characters' } }, $character );

    $self -> { 'characters_by_id' } -> { $character -> id() } = $#{ $self -> { 'characters' } };

    weaken( my $weak = $self );

    $character -> player( $weak );

    return $character;
}

sub remove_character {

    my ( $self, $character ) = @_;

    my $index = $self -> { 'characters_by_id' } -> { $character -> id() };

    splice( @{ $self -> { 'characters' } }, $index, 1 );

    foreach my $index ( $index .. $#{ $self -> { 'characters' } } ) {

        -- $self -> { 'characters_by_id' } -> { $self -> { 'characters' } -> [ $index ] -> id() };
    }

    return $character;
}

sub id {

    return shift -> accessor( id => @_ );
}

sub name {

    return shift -> accessor( name => @_ );
}

sub characters {

    my ( $self ) = @_;

    return $self -> { 'characters' };
}

sub is_alive {

    my ( $self ) = @_;

    return ( scalar( @{ $self -> { 'characters' } } ) > 0 );
}

sub tick {

    my ( $self ) = @_;

    foreach my $character ( @{ $self -> { 'characters' } } ) {

        $character -> tick();
    }

    return;
}

sub turn {

    my ( $self ) = @_;

    foreach my $character ( @{ $self -> { 'characters' } } ) {

        $character -> turn();
    }

    return;
}

1;

__END__
