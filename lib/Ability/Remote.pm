package Ability::Remote;

use strict;
use warnings;

use base 'Ability';

sub range {

    return shift -> accessor( range => @_ );
}

sub area {

    return shift -> accessor( area => @_ );
}

1;

__END__
