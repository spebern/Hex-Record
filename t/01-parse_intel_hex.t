use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 8 }
use Test::Warn;
use Hex::Record::Parser qw(parse_intel_hex);

my ($intel_hex_string, $parts_expected, $parts_ref);

$intel_hex_string = <<'END_HEX_RECORD';
:0A00000000010203040506070809C9
:0A000A00101112131415161718191F
:0A0014002021222324252627282975
:00000001FF
END_HEX_RECORD


$parts_expected = [
    {
        start => 0x0,
        bytes => [
            qw(00 01 02 03 04 05 06 07 08 09
               10 11 12 13 14 15 16 17 18 19
               20 21 22 23 24 25 26 27 28 29),
        ],
    },
];

$parts_ref = parse_intel_hex( $intel_hex_string );


$intel_hex_string = <<'END_HEX_RECORD';
:0A000A00101112131415161718191F
:0A0014002021222324252627282975
:0A00000000010203040506070809C9
END_HEX_RECORD


is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed simple intel hex correctly');

$parts_ref = parse_intel_hex( $intel_hex_string );

is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed simple intel hex in wrong order correctly');

$intel_hex_string = <<'END_HEX_RECORD';
:0A00000000010203040506070809C9
:0A0009001011121314151617181920
:0A0014002021222324252627282975
:00000001FF
END_HEX_RECORD

$parts_expected = [
    {
        start  => 0x0,
        bytes => [
            qw(00 01 02 03 04 05 06 07 08 10
               11 12 13 14 15 16 17 18 19),
        ],
    },
    {
        start => 0x14,
        bytes =>[
            qw(20 21 22 23 24 25 26 27 28 29),
        ],
    },
];

warning_is
    { $parts_ref = parse_intel_hex( $intel_hex_string ) }
    "colliding parts: 0 .. 10 with part: 9 .. 19 ... overwriting",
    "warned of colliding parts";

is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed intel hex with simple overwrite, two parts');



$intel_hex_string = <<'END_HEX_RECORD';
:0A00000000010203040506070809C9
:0A0003001011121314151617181926
:0A0005002021222324252627282984
:00000001FF
END_HEX_RECORD


$parts_expected = [
    {
        start => 0x0,
        bytes => [
            qw(00 01 02 10 11 20 21 22 23 24
               25 26 27 28 29),
        ],
    },
];

warnings_are
    { $parts_ref = parse_intel_hex( $intel_hex_string ) }
    [ "colliding parts: 0 .. 10 with part: 3 .. 13 ... overwriting",
      "colliding parts: 0 .. 13 with part: 5 .. 15 ... overwriting", ],
    "warned of colliding parts";

is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed intel hex with three parts overwrite correctly');

$intel_hex_string = <<'END_HEX_RECORD';
:020000040000FA
:0A00000000112233445566778899F9
:0A000A0099887766554433221100EF
:02000004FFFFFC
:0A00010000112233445566778899F8
:0A000B0099887766554433221100EE
:020000040001F9
:0AFF000000112233445566778899FA
:0AFF0A0099887766554433221100F0
END_HEX_RECORD

$parts_expected = [
    {
        start => 0x0,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
    {
        start => 0x0001FF00,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
    {
        start => 0xFFFF0001,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
];

$parts_ref = parse_intel_hex( $intel_hex_string );

is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed intel hex with extended linear address offsets correctly');


$intel_hex_string = <<'END_HEX_RECORD';
:020000020000FC
:0A00000000112233445566778899F9
:0A000A0099887766554433221100EF
:02000002FFFFFE
:0A00010000112233445566778899F8
:0A000B0099887766554433221100EE
:020000020001FB
:0AFF000000112233445566778899FA
:0AFF0A0099887766554433221100F0
END_HEX_RECORD


$parts_expected = [
    {
        start => 0x0,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
    {
        start => 0xFF10,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
    {
        start => 0xFFFF1,
        bytes => [
            qw(00 11 22 33 44 55 66 77 88 99
               99 88 77 66 55 44 33 22 11 00),
        ],
    },
];

$parts_ref = parse_intel_hex( $intel_hex_string );

is_deeply(
    $parts_ref,
    $parts_expected,
    'parsed intel hex with extended segment address offsets correctly');

