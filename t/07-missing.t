use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 't/lib';

like(
    exception {

        package A;
        use Foo ();
        Foo->import( plugin_dir => 'Missing', plugins => 'Bar' );
    },
    qr/plugin_dir.*does not exist/,
    "missing plugin directory"
);

done_testing;
