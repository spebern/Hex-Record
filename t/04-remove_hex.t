use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 11 }
use Storable qw(dclone);

use Hex::Record;

my $hex_original = Hex::Record->new(
    _hex_parts => [
        [
            0x0,
            [
                qw(00),
            ],
        ],
        [
            0x10,
            [
                qw(00 11 22),
            ],
        ],
        [
            0x100,
            [
                qw(00 01 02 03 04 05 06 07 08 09
                   10 11 12 13 14 15 16 17 18 19
                   20 21 22 23 24 25 26 27 28 29
                   30 31 32 33 34 35 36 37 38 39
                   40 41 42 43 44 45 46 47 48 49),
            ],
        ],
        [
            0x1000,
            [
                qw(FF FF FF),
            ],
        ],
    ],
);

my @remove_bytes_tests = (
    {
        from  => 0,
        count => 1,
        expected_hex_parts => [
            [
                0x10,
                [
                    qw(00 11 22),
                ],
            ],
            [
                0x100,
                [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0,
        count => 19,
        expected_hex_parts => [
            [
                0x100,
                [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0,
        count => 306,
        expected_hex_parts => [
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0,
        count => 4099,
        expected_hex_parts => [],
    },
    {
        from  => 0x100,
        count => 5,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x10,
                [
                    qw(00 11 22),
                ],
            ],
            [
                0x105,
                [
                    qw(               05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0x11,
        count => 2,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x10,
                [
                    qw(00),
                ],
            ],
            [
                0x100,
                [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0x10,
        count => 3,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x100,
                [
                    qw(00 01 02 03 04 05 06 07 08 09
                       10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0,
        count => 1000000000000000000000000000,
        expected_hex_parts => [],
    },
    {
        from  => 0x105,
        count => 5,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x10,
                [
                    qw(00 11 22),
                ],
            ],
            [
                0x100,
                [
                    qw(00 01 02 03 04)
                ],
            ],
            [
                0x10A,
                [
                    qw(10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF),
                ],
            ],
        ],
    },
    {
        from  => 0x105,
        count => 5,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x10,
                [
                    qw(00 11 22),
                ],
            ],
            [
                0x100,
                [
                    qw(00 01 02 03 04)
                ],
            ],
            [
                0x10A,
                [
                    qw(10 11 12 13 14 15 16 17 18 19
                       20 21 22 23 24 25 26 27 28 29
                       30 31 32 33 34 35 36 37 38 39
                       40 41 42 43 44 45 46 47 48 49),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF)
                ],
            ],
        ],
    },
    {
        from  => 0x08,
        count => 4000,
        expected_hex_parts => [
            [
                0x0,
                [
                    qw(00),
                ],
            ],
            [
                0x1000,
                [
                    qw(FF FF FF)
                ],
            ],
        ],
    },
);

for my $remove_bytes_test (@remove_bytes_tests) {
    my $hex_copy =  dclone $hex_original;

    my $from  = $remove_bytes_test->{from};
    my $count = $remove_bytes_test->{count};


    $hex_copy->remove( $from, $count );

    is_deeply(
        $hex_copy->{_hex_parts},
        $remove_bytes_test->{expected_hex_parts},
        "successfully removed $count bytes from $from"
    );
}

