package Hex::Record::Parser;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(
    parse_intel_hex
    parse_srec_hex);

our $VERSION = '0.01';

use Hex::Record;

sub parse_intel_hex {
    my ( $file ) = @_;

    open(my $fh, '<', $file) || die "could not open $file: $!";

    my $hex           = Hex::Record->new;
    my $addr_high_dec = 0;

    my @hex_parts;
    while ( my $line = <$fh> ){
        $line =~ m{
		  : # intel hex start
		   [[:xdigit:]]{2}  # bytecount
		  ([[:xdigit:]]{4}) # addr
		  ([[:xdigit:]]{2}) # type
		  ([[:xdigit:]] * ) # databytes
	       	   [[:xdigit:]]{2}  # checksum
	      }ix or next;

        my $intel_type_dec = $2;
        my @bytes_hex      = unpack( '(A2)*', $3 );

        # data line?
        if ( $intel_type_dec == 0 ) {
            push @hex_parts, [ $addr_high_dec + hex($1), \@bytes_hex ];
        }

        # extended linear address type?
        elsif ( $intel_type_dec == 4 ) {
            $addr_high_dec = hex( join '', @bytes_hex ) << 16;
        }

        # extended segment address type?
        elsif ( $intel_type_dec == 2 ) {
            $addr_high_dec = hex( join '', @bytes_hex ) << 4;
        }
    }


    $hex->_set_merged_parts([ sort { $a->[0] <=> $b->[0] } @hex_parts ] );
    return $hex;
}

my %_address_length_of_srec_type = (
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

sub parse_srec_hex {
    my ( $file ) = @_;

    open my $fh, '<', $file || die "could not open file: $!";

    my $hex = Hex::Record->new;

    my @hex_parts;
    while ( my $line = <$fh> ){
        next unless substr( $line, 0, 1 ) =~ m{s}i;

        my $type = substr $line, 1, 1;

        my $addr_length = $_address_length_of_srec_type{$type};

        $line =~ m{
		      s #srec hex start
		  ([[:xdigit:]]{1})             #type
		   [[:xdigit:]]{2}              #bytecount
		  ([[:xdigit:]]{$addr_length})  #addr
		  ([[:xdigit:]] * )             #databytes
		   [[:xdigit:]]{2}              #checksum
	      }ix or next;

        #data line?
        if ( $1 == 0 || $1 == 1 || $1 == 2 || $1 == 3) {
            push @hex_parts, [ hex $2, [ unpack '(A2)*', $3 ] ];
        }
    }

    $hex->_set_merged_parts( [ sort { $a->[0] <=> $b->[0] } @hex_parts ] );

    #sort the bytes of the record
    return $hex;
}

1;


=head1 NAME

Hex::Record::Parser - parse intel and srec hex records

=head1 SYNOPSIS

    use Hex::Parser qw(parse_intel_hex parse_srec_hex);

    # for intel hex record
    my $hex_record = parse_intel_hex( 'intel.hex' );

    # for srec hex record
    my $hex_record = parse_srec_hex( 'srec.hex' );

=head1 DESCRIPTION

parse intel/srec hex files.

=head2 Functions

=over 12

=item C<parse_intel_hex( $intel_hex_file_name )>

Exported by Hex::Parser
parses intel hex file. Returns Hex object.

=item C<parse_srec_hex( $srec_hex_file_name )>

Exported by Hex::Parser
parses srec hex file. Returns Hex object.

=back

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
