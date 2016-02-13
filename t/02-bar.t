use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Foo plugins => ['Bar'];
use Foo::A;
use Foo::B;

can_ok( 'Foo::A', 'a' );
can_ok( 'Foo::A', 'bar_a' );
ok( !Foo::B->can('baz_a'), 'no Foo::B->baz_a' );

can_ok( 'Foo::B', 'b' );
ok( !Foo::B->can('baz_b'), 'no Foo::B->baz_b' );

done_testing;
