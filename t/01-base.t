use strict;
use warnings;
use Test::More;

use lib 't/lib';

use Foo plugin_base_classes => ['A','B'];
use Foo::A;
use Foo::B;

can_ok( 'Foo::A', 'a' );
ok( !Foo::A->can('bar_a'), 'no Foo::A->bar_a' );

can_ok( 'Foo::B', 'b' );
ok( !Foo::B->can('baz_b'), 'no Foo::B->baz_b' );

done_testing;
