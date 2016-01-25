use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 1 }

use Hex::Record;

my $hex = Hex::Record->new();
# merge two parts
$hex->write(0,    [map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(20,   [map { sprintf "%2X", $_ } 20 .. 29 ]);


$hex->write(100,  [map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(130,  [map { sprintf "%2X", $_ }  0 .. 19 ]);
$hex->write(80,   [map { sprintf "%2X", $_ }  0 .. 99 ]);

$hex->write(1010, [map { sprintf "%2X", $_ } 10 .. 19 ]);
$hex->write(1000, [map { sprintf "%2X", $_ }  0 .. 9  ]);


my $hex_parts_expected = [
    [
        0,
        [map { sprintf "%2X", $_ }  0 .. 29 ]
    ],
    [
        80,
        [map { sprintf "%2X", $_ }  0 .. 99],
    ],
    [
        1000,
        [map { sprintf "%2X", $_ }  0 .. 19]
    ],
];

is_deeply( $hex->{hex_parts},
           $hex_parts_expected,
           "successfully written hex parts" );

