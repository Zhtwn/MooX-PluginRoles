use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Quux plugins => ['Bar'];
use Quux::A;

can_ok( 'Quux::A', 'a' );
can_ok( 'Quux::A', 'bar_a' );

done_testing;
