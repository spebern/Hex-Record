package Hex::Record::Parser;

use strict;
use warnings;
use Carp;

use parent 'Exporter';
our @EXPORT_OK = qw(
    parse_intel_hex
    parse_srec_hex);

our $VERSION = '0.04';

use Hex::Record;

sub parse_intel_hex {
    my ($hex_string) = @_;

    my $addr_high_dec = 0;

    my @hex_parts;
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
            push @hex_parts, [$addr_high_dec + hex($1), \@bytes_hex];
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

    return _get_merged_parts(\@hex_parts);
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

    my @hex_parts;
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
            push @hex_parts, [ hex $2, [ unpack '(A2)*', $3 ] ];
        }
    }

    #sort the bytes of the record
    return _get_merged_parts(\@hex_parts);
}

sub _get_merged_parts {
    my ($hex_parts_ref) = @_;

    return unless @$hex_parts_ref;

    @$hex_parts_ref = sort { $a->[0] <=> $b->[0] } @$hex_parts_ref;

    # set first part
    my @merged_parts          = shift @$hex_parts_ref;
    my $merged_parts_end_addr = $merged_parts[-1]->[0] + @{ $merged_parts[-1]->[1] };

    for my $hex_part_ref (@$hex_parts_ref) {

        my $hex_part_start_addr = $hex_part_ref->[0];
        my $hex_part_byte_count = @{ $hex_part_ref->[1] };
        my $hex_part_end_addr   = $hex_part_start_addr + $hex_part_byte_count;

        # overwrite?
        if ($hex_part_start_addr < $merged_parts_end_addr){
            # remove parts completly inlcuded
            my $warning = "colliding parts: ";

            while ($hex_part_start_addr < $merged_parts[-1]->[0]){
                my $removed_part = pop @merged_parts;
                $warning .= $removed_part->[0] . ' .. ' . ($removed_part->[0] +  @{$removed_part->[1]}) . ', ';
            }

            $warning .=
                $merged_parts[-1]->[0] . ' .. ' . ( $merged_parts[-1]->[0] +  @{$merged_parts[-1]->[1]} )
                . ' with part: '
                . $hex_part_start_addr . ' .. '  . $hex_part_end_addr
                . " ... overwriting";

            carp $warning;

            my $part_offset = $hex_part_start_addr - $merged_parts[-1]->[0];

              @{$merged_parts[-1]->[1]}[$part_offset .. $part_offset + $hex_part_byte_count - 1]
            = @{$hex_part_ref->[1]};
        }

        #append?
        elsif ($hex_part_start_addr == $merged_parts_end_addr){
            push @{$merged_parts[-1]->[1]}, @{$hex_part_ref->[1]};
        }

        #new part!
        else {
            push @merged_parts, $hex_part_ref;
        }

        #set new addr
        $merged_parts_end_addr = $hex_part_end_addr if $hex_part_end_addr > $merged_parts_end_addr;
    }

    return \@merged_parts;
}



1;


=head1 NAME

Hex::Record::Parser - parse intel and srec hex records

=head1 SYNOPSIS

    use Hex::Record::Parser qw(parse_intel_hex parse_srec_hex);

    # for intel hex record
    my $hex_parts_ref = parse_intel_hex( $intel_hex_record_as_string );

    # for srec hex record
    my $hex_parts_ref = parse_srec_hex( $srec_hex_record_as_string );

    # the sctucture returned by the parser will look like this
    # the part start addresses (0x100, 0xFFFFF in example) are sorted
    my $hex_parts_ref = [
        0x100   => [qw(11 22 33 44 55 66)],
        0xFFFFF => [qw(77 88 99 AA BB CC)],
    ];

    # create hex records, to manipulate and dump hex data
    use Hex::Record;

    my $hex_record = Hex::Record->new(
        hex_parts => $hex_parts_ref
    );


=head1 DESCRIPTION

parse intel/srec hex files.

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
