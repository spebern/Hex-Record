use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 7 }

use Hex::Record;

my ($hex, @bytes, @bytes_expected, $first_hex_part_expected);

$hex = Hex::Record->new(
    _hex_parts => [
        [
            0x0,
            [
                qw(00 11 22 33 44 55 66 77 88 99),
            ],
        ],
        [
            0xA,
            [
                qw(AA),
            ],
        ],
        [
            0xC,
            [
                qw(CC),
            ],
        ],
        [
            0x0000FFF0,
            [
                qw(00 01 02 03 04 05 06 07 08 09
                   10 11 12 13 14 15 16 17 18 19
                   20 21 22 23 24 25 26 27 28 29
                   30 31 32 33 34 35 36 37 38 39
                   40 41 42 43 44 45 46 47 48 49),
            ],
        ],
        [
            0xFF0000,
            [
                qw(00 11 22 33 44 55 66 77 88 99),
            ],
        ],
        [
            0xFFFFFF00,
            [
                qw(00 11 22 33 44 55 66 77 88 99),
            ],
        ],
    ],
);

# get
my @get_bytes_tests = (
    {
        from     => 0x0,
        count    => 13,
        expected => [ qw(00 11 22 33 44 55 66 77 88 99), undef, qw(AA), undef, undef, qw(CC) ],
    },
    {
        from     => 0x0,
        count    => 10,
        expected => [ qw(00 11 22 33 44 55 66 77 88 99) ],
    },
    {
        from     => 0x0,
        count    => 1,
        expected => [ qw(00) ],
    },
    {
        from     => 0x100000,
        count    => 1,
        expected => [ undef ],
    },
    {
        from     => 0x100000,
        count    => 10,
        expected => [ (undef) x 10 ],
    },
    {
        from     => 0xFFFFFF05,
        count    => 10,
        expected => [ qw(55 66 77 88 99), undef, undef, undef, undef, undef ],
    },
    {
        from     => 0x0000FFF0,
        count    => 50,
        expected => [
            qw(00 01 02 03 04 05 06 07 08 09
               10 11 12 13 14 15 16 17 18 19
               20 21 22 23 24 25 26 27 28 29
               30 31 32 33 34 35 36 37 38 39
               40 41 42 43 44 45 46 47 48 49),
        ],
    },
);

for my $get_bytes_test ( @get_bytes_tests ){
    my $from  = $get_bytes_test->{from};
    my $count = $get_bytes_test->{count};

    my $bytes_expected_ref = $get_bytes_test->{expected};

    is_deeply( $hex->get($from, $count),
               $bytes_expected_ref,
               "expected $count bytes correctly from $from" );
}