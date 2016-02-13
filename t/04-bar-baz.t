use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Foo plugins => [ 'Bar', 'Baz' ];
use Foo::A;
use Foo::B;

can_ok( 'Foo::A', 'a' );
can_ok( 'Foo::A', 'bar_a' );

can_ok( 'Foo::B', 'b' );
can_ok( 'Foo::B', 'baz_b' );

done_testing;
