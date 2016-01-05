use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 8 }
use Test::Warn;
use Hex::Record::Parser qw(parse_srec_hex);
use File::Basename;

my ($srec_hex_string, $hex_parts_expected, $hex);

my $dir = dirname(__FILE__) . '/hex_files/srec/';

$hex_parts_expected = [
    [
        0x0,
        [
            qw(00 01 02 03 04 05 06 07 08 09
               10 11 12 13 14 15 16 17 18 19
               20 21 22 23 24 25 26 27 28 29),
        ],
    ],
];

$hex = parse_srec_hex( $dir . 'simple.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed simple srec hex correctly');

$hex = parse_srec_hex( $dir . 'unordered.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed simple srec hex in wrong order correctly');

$hex_parts_expected = [
    [
        0x0,
        [
            qw(00 01 02 03 04 05 06 07 08 10
               11 12 13 14 15 16 17 18 19),
        ],
    ],
    [
        0x14,
        [
            qw(20 21 22 23 24 25 26 27 28 29),
        ],
    ],
];

warning_is
    { $hex = parse_srec_hex( $dir . 'simple_overwrite.hex' ) }
    "colliding parts: 0 .. 10 with part: 9 .. 19 ... overwriting",
    "warned of colliding parts";

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed srec hex with simple overwrite, two parts');

$hex_parts_expected = [
    [
        0x0,
        [
            qw(00 01 02 10 11 20 21 22 23 24
               25 26 27 28 29),
        ],
    ],
];

warnings_are
    { $hex = parse_srec_hex( $dir . 'three_parts_overwrite.hex' ) }
    [ "colliding parts: 0 .. 10 with part: 3 .. 13 ... overwriting",
      "colliding parts: 0 .. 13 with part: 5 .. 15 ... overwriting", ],
    "warned of colliding parts";

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed srec hex with simple overwrite, two parts');

$hex_parts_expected = [
    [
        0x10000,
        [
            qw(FF FF FF FF FF FF FF FF FF 33),
        ],
    ],
    [
        0x10000A,
        [
            qw(99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0xFF0001,
        [
            qw(00 11 22 33 44 55 66 77 88 99),
        ],
    ],
];

$hex = parse_srec_hex( $dir . '24_bit_addr.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed srec hex with 24 bit addresses correctly');

$hex_parts_expected = [
    [
        0x01000001,
        [
            qw(FF FF FF FF FF FF FF FF FF 33),
        ],
    ],
    [
        0x10000A0F,
        [
            qw(99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0xFF000101,
        [
            qw(00 11 22 33 44 55 66 77 88 99),
        ],
    ],
];

$hex = parse_srec_hex( $dir . '32_bit_addr.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed srec hex with 32 bit addresses correctly');

