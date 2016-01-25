use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 8 }
use Test::Warn;
use Hex::Record::Parser qw(parse_srec_hex);

my ($srec_hex_string, $hex_parts_expected, $hex_parts_ref);

$srec_hex_string = <<'END_HEX_RECORD';
S10C000000010203040506070809C6
S10C000A101112131415161718191C
S10C00142021222324252627282972
END_HEX_RECORD

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

$hex_parts_ref = parse_srec_hex( $srec_hex_string );

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed simple srec hex correctly');


$srec_hex_string = <<'END_HEX_RECORD';
S10C00142021222324252627282972
S10C000A101112131415161718191C
S10C000000010203040506070809C6
END_HEX_RECORD


$hex_parts_ref = parse_srec_hex( $srec_hex_string );

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed simple srec hex in wrong order correctly');


$srec_hex_string = <<'END_HEX_RECORD';
S10C000000010203040506070809C6
S10C0009101112131415161718191D
S10C00142021222324252627282972
END_HEX_RECORD


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
    { $hex_parts_ref = parse_srec_hex( $srec_hex_string ) }
    "colliding parts: 0 .. 10 with part: 9 .. 19 ... overwriting",
    "warned of colliding parts";

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed srec hex with simple overwrite, two parts');

$srec_hex_string = <<'END_HEX_RECORD';
S10C000000010203040506070809C6
S10C00031011121314151617181923
S10C00052021222324252627282981
END_HEX_RECORD

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
    { $hex_parts_ref = parse_srec_hex( $srec_hex_string ) }
    [ "colliding parts: 0 .. 10 with part: 3 .. 13 ... overwriting",
      "colliding parts: 0 .. 13 with part: 5 .. 15 ... overwriting", ],
    "warned of colliding parts";

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed srec hex with simple overwrite, two parts');
    
$srec_hex_string = <<'END_HEX_RECORD';
S20C010000FFFFFFFFFFFFFFFFFF33C8
S20CFF000100112233445566778899F6
S20C10000A99887766554433221100DC
END_HEX_RECORD

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

$hex_parts_ref = parse_srec_hex( $srec_hex_string );

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed srec hex with 24 bit addresses correctly');

$srec_hex_string = <<'END_HEX_RECORD';
S30C01000001FFFFFFFFFFFFFFFFFF33C7
S30CFF00010100112233445566778899F5
S30C10000A0F99887766554433221100CD
END_HEX_RECORD

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

$hex_parts_ref = parse_srec_hex( $srec_hex_string );

is_deeply(
    $hex_parts_ref,
    $hex_parts_expected,
    'parsed srec hex with 32 bit addresses correctly');

