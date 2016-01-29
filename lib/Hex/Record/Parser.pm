package Hex::Record::Parser;

use strict;
use warnings;
use Carp;

use parent 'Exporter';
our @EXPORT_OK = qw(
    parse_intel_hex
    parse_srec_hex);

our $VERSION = '0.05';

use Hex::Record;

sub parse_intel_hex {
    my ($hex_string) = @_;

    my $addr_high_dec = 0;

    my @parts;
    for my $line (split m{\n\r?}, $hex_string) {
        $line =~ m{
		  : # intel hex start
		   [[:xdigit:]]{2}  # bytecount
		  ([[:xdigit:]]{4}) # addr
		  ([[:xdigit:]]{2}) # type
		  ([[:xdigit:]] * ) # databytes
	       	   [[:xdigit:]]{2}  # checksum
	      }ix or next;

        my $intel_type_dec = $2;
        my @bytes_hex      = unpack('(A2)*', $3);

        # data line?
        if ($intel_type_dec == 0){
            push @parts, {
                start => $addr_high_dec + hex($1),
                bytes => \@bytes_hex
            };
        }

        # extended linear address type?
        elsif ($intel_type_dec == 4){
            $addr_high_dec = hex( join '', @bytes_hex ) << 16;
        }

        # extended segment address type?
        elsif ($intel_type_dec == 2){
            $addr_high_dec = hex( join '', @bytes_hex ) << 4;
        }
    }

    return _get_merged_parts(\@parts);
}

sub parse_srec_hex {
    my ($hex_string) = @_;

    my %address_length_of_srec_type = (
        0 => '4',
        1 => '4',
        2 => '6',
        3 => '8',
        4 => undef,
        5 => '4',
        6 => '6',
        7 => '8',
        8 => '6',
        9 => '4',
    );

    my @parts;
    for my $line (split m{\n\r?}, $hex_string) {
        next unless substr( $line, 0, 1 ) =~ m{s}i;

        my $type = substr $line, 1, 1;

        my $addr_length = $address_length_of_srec_type{$type};

        $line =~ m{
		      s #srec hex start
		  ([[:xdigit:]]{1})             #type
		   [[:xdigit:]]{2}              #bytecount
		  ([[:xdigit:]]{$addr_length})  #addr
		  ([[:xdigit:]] * )             #databytes
		   [[:xdigit:]]{2}              #checksum
	      }ix or next;

        #data line?
        if ($1 == 0 || $1 == 1 || $1 == 2 || $1 == 3){
            push @parts, {
                start => hex $2,
                bytes => [ unpack '(A2)*', $3 ]
            };
        }
    }

    #sort the bytes of the record
    return _get_merged_parts(\@parts);
}

sub _get_merged_parts {
    my ($parts_ref) = @_;

    return unless @$parts_ref;

    @$parts_ref = sort { $a->{start} <=> $b->{start} } @$parts_ref;

    # set first part
    my @merged_parts          = shift @$parts_ref;
    my $merged_parts_end_addr = $merged_parts[-1]->{start} + @{ $merged_parts[-1]->{bytes} };

    for my $part_ref (@$parts_ref) {

        my $part_start_addr = $part_ref->{start};
        my $part_byte_count = @{ $part_ref->{bytes} };
        my $part_end_addr   = $part_start_addr + $part_byte_count;

        # overwrite?
        if ($part_start_addr < $merged_parts_end_addr){
            # remove parts completly inlcuded
            my $warning = "colliding parts: ";

            while ($part_start_addr < $merged_parts[-1]->{start}){
                my $removed_part = pop @merged_parts;
                $warning .= $removed_part->{start} . ' .. '
                          . ($removed_part->{start} +  @{$removed_part->{bytes}}) . ', ';
            }

            $warning .=
                $merged_parts[-1]->{start} . ' .. '
                . ( $merged_parts[-1]->{start} +  @{$merged_parts[-1]->{bytes}} )
                . ' with part: '
                . $part_start_addr . ' .. '  . $part_end_addr
                . " ... overwriting";

            carp $warning;

            my $part_offset = $part_start_addr - $merged_parts[-1]->{start};

              @{$merged_parts[-1]->{bytes}}[$part_offset .. $part_offset + $part_byte_count - 1]
            = @{$part_ref->{bytes}};
        }

        #append?
        elsif ($part_start_addr == $merged_parts_end_addr){
            push @{$merged_parts[-1]->{bytes}}, @{$part_ref->{bytes}};
        }

        #new part!
        else {
            push @merged_parts, $part_ref;
        }

        #set new addr
        $merged_parts_end_addr = $part_end_addr if $part_end_addr > $merged_parts_end_addr;
    }

    return \@merged_parts;
}



1;


=head1 NAME

Hex::Record::Parser - parse intel and srec hex records

=head1 SYNOPSIS

    use Hex::Record::Parser qw(parse_intel_hex parse_srec_hex);

    # for intel hex record
    my $hex_parts_ref = parse_intel_hex($intel_hex_record_as_string);

    # for srec hex record
    my $hex_parts_ref = parse_srec_hex($srec_hex_record_as_string);

    # the sctucture returned by the parser will look like this
    # the part start addresses (0x100, 0xFFFFF in example) are sorted
    my $hex_parts_ref = [
        {
            start => 0x100,
            bytes => [qw(11 22 33 44 55 66)],
        },
        {
            start => 0xFFFFF,
            bytes => [qw(77 88 99 AA BB CC)],
        },
    ];

    # create hex records, to manipulate and dump hex data
    use Hex::Record;

    my $hex_record = Hex::Record->new(
        parts => $hex_parts_ref
    );


=head1 DESCRIPTION

parse intel/srec hex files.

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
