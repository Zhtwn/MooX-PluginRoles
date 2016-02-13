use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';

package A;
use Foo;

package main;

like(
    exception { package B; use Foo (); Foo->import(plugins => ['Bar']); },
    qr/PluginRoles conflict/,
    "conflicting plugins fail"
);

use Foo::A;
use Foo::B;

can_ok( 'Foo::A', 'a' );
ok( !Foo::A->can('bar_a'), 'no Foo::A->bar_a' );

can_ok( 'Foo::B', 'b' );
ok( !Foo::B->can('baz_b'), 'no Foo::B->baz_b' );

done_testing;
