use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 8 }
use Test::Warn;
use Hex::Record::Parser qw(parse_intel_hex);
use File::Basename;

my ($intel_hex_string, $hex_parts_expected, $hex);

my $dir = dirname(__FILE__) . '/hex_files/intel/';

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

$hex = parse_intel_hex( $dir . 'simple.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed simple intel hex correctly');

$hex = parse_intel_hex( $dir . 'unordered.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed simple intel hex in wrong order correctly');

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
    { $hex = parse_intel_hex( $dir . 'simple_overwrite.hex' ) }
    "colliding parts: 0 .. 10 with part: 9 .. 19 ... overwriting",
    "warned of colliding parts";

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed intel hex with simple overwrite, two parts');

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
    { $hex = parse_intel_hex( $dir . 'three_parts_overwrite.hex' ) }
    [ "colliding parts: 0 .. 10 with part: 3 .. 13 ... overwriting",
      "colliding parts: 0 .. 13 with part: 5 .. 15 ... overwriting", ],
    "warned of colliding parts";

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed intel hex with extended linear address offsets correctly');

$hex_parts_expected = [
    [
        0x0,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0x0001FF00,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0xFFFF0001,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
];

$hex = parse_intel_hex( $dir . 'ext_lin_addr.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed intel hex with extended linear address offsets correctly');

$hex_parts_expected = [
    [
        0,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0xFF10,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
    [
        0xFFFF1,
        [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    ],
];

$hex = parse_intel_hex( $dir . 'ext_seg_addr.hex' );

is_deeply(
    $hex->{_hex_parts},
    $hex_parts_expected,
    'parsed intel hex with extended segment address offsets correctly');

