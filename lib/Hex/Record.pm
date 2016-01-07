package Hex::Record;

use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

sub new {
    my ( $class, %args  ) = @_;

    %args = (_hex_parts => []) unless %args;

    return bless \%args, $class;
}

sub write {
    my ( $self, $from, $bytes_hex_ref ) = @_;

    $self->remove( $from, scalar @$bytes_hex_ref );

    my $to = $from + @$bytes_hex_ref;

    # insert part
    for ( my $hex_part_i = 0; $hex_part_i < @{$self->{_hex_parts}}; $hex_part_i++ ){
        my $hex_part = $self->{_hex_parts}->[$hex_part_i];

        my $start_addr = $hex_part->[0];
        my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

        # merge with this part
        if ( $to == $start_addr ){
            $hex_part->[0] = $from;
            unshift @{$hex_part->[1]}, @$bytes_hex_ref;
            return;
        }
        elsif ( $from == $end_addr+1 ){
            push @{$hex_part->[1]}, @$bytes_hex_ref;

            return if $hex_part_i+1 == @{$self->{_hex_parts}};

            my $next_part = $self->{_hex_parts}->[$hex_part_i+1];
            # merge with next part
            if ( $to == $next_part->[0] - 1 ){
                push @{$hex_part->[1]}, @{$next_part->[1]};
                splice @{$self->{_hex_parts}}, $hex_part_i+1, 1;
            }
            return;
        }
        elsif ( $from < $start_addr ){
            splice @{$self->{_hex_parts}}, $hex_part_i, 0, [ $from, $bytes_hex_ref ];
            return;
        }
    }

    push @{$self->{_hex_parts}}, [ $from, $bytes_hex_ref ];
    return;
}

sub get {
    my ( $self, $from, $length ) = @_;

    my $to = $from + $length-1;

    my @bytes_hex;
    for ( my $hex_part_i = 0; $hex_part_i < @{$self->{_hex_parts}}; $hex_part_i++ ){
        my $hex_part = $self->{_hex_parts}->[$hex_part_i];

        my $start_addr = $hex_part->[0];
        my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

        # from inside this part
        if ( $from >= $start_addr && $from <= $end_addr ){

            # this part also includes end
            if ( $to <= $end_addr ){
                @bytes_hex = @{$hex_part->[1]}[ $from - $start_addr .. $to - $start_addr ];
                return \@bytes_hex;
            }
            else {
                @bytes_hex = @{$hex_part->[1]}[ $from - $start_addr .. $#{$hex_part->[1]} ];

                while ( ++$hex_part_i < @{$self->{_hex_parts}} ){
                    my $hex_part = $self->{_hex_parts}->[$hex_part_i];

                    my $start_addr = $hex_part->[0];
                    my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};
                    # desired part ended before this one
                    if ( $to < $start_addr ){
                        return [ @bytes_hex, (undef) x ($length - @bytes_hex) ];
                    }

                    else {
                        # fill gap betwenn this part and part before with undef
                        my $hex_part_before             = $self->{_hex_parts}->[$hex_part_i - 1];
                        my $hex_part_before_end_addr = $hex_part_before->[0] + $#{$hex_part_before->[1]};

                        push @bytes_hex, (undef) x ($start_addr - $hex_part_before_end_addr);

                        if ( $to <= $end_addr ){
                            push @bytes_hex, @{$hex_part->[1]}[ 0 .. $to - $start_addr ];
                            return \@bytes_hex;
                        }

                        push @bytes_hex, @{$hex_part->[1]};
                    }
                }
            }
        }

        # did not find start, but did find end
        elsif ( $to <= $end_addr  && $to >= $start_addr ){
            @bytes_hex = ( (undef) x ($start_addr - $from),
                       @{$hex_part->[1]}[ 0 .. $to - $start_addr ] );
            return \@bytes_hex;
        }
    }
    return [ @bytes_hex, (undef) x ($length - @bytes_hex) ];
}

sub remove {
    my ( $self, $from, $length ) = @_;

    my $to = $from + $length-1;

    for ( my $hex_part_i = 0; $hex_part_i < @{ $self->{_hex_parts} }; $hex_part_i++ ){
        my $hex_part = $self->{_hex_parts}->[$hex_part_i];

        my $start_addr = $hex_part->[0];
        my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

        if ( $from <= $end_addr ){
            if ( $to <= $end_addr ){
                if ( $from <= $start_addr ){
                    if ( $to == $end_addr ){
                        splice @{$self->{_hex_parts}}, $hex_part_i, 1;
                    }
                    else {
                        splice @{$hex_part->[1]}, 0, @{$hex_part->[1]} - $end_addr+$to;;
                        $hex_part->[0] = $to+1;
                    }
                    return;
                }
                elsif ( $to == $end_addr ){
                    splice @{$hex_part->[1]}, $from-$start_addr, $length;
                }
                else {
                    splice @{$self->{_hex_parts}}, $hex_part_i, 1, (
                        [
                            $start_addr,
                            [@{$hex_part->[1]}[ 0 .. $from - $start_addr - 1] ],
                        ],
                        [
                            $from + $length,
                            [@{$hex_part->[1]}[ $from - $start_addr + $length .. $#{$hex_part->[1]}]],
                        ],
                    );
                }
                return;
            }
            else {
                splice @{$self->{_hex_parts}}, $hex_part_i, 1;
                --$hex_part_i;
            }
            while ( ++$hex_part_i < @{$self->{_hex_parts}} ){
                my $hex_part = $self->{_hex_parts}->[$hex_part_i];

                my $start_addr = $hex_part->[0];
                return if $to < $start_addr;

                my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

                if ( $to < $end_addr ){
                    splice @{$hex_part->[1]}, 0, $to-$start_addr+1;
                    $hex_part->[0] = $to + 1;
                    return;
                }
                splice @{$self->{_hex_parts}}, $hex_part_i, 1;
                --$hex_part_i;

                return if $to == $end_addr;
            }
        }
        elsif ( $to <= $end_addr ){
            splice @{$hex_part->[1]}, 0, $to-$start_addr+1;
            $hex_part->[1] = $to + 1;
            return;
        }
    }
}

sub as_intel_hex {
    my ($self, $bytes_hex_a_line) = @_;

    my $intel_hex_string = '';
    for ( my $hex_part_i = 0; $hex_part_i < @{ $self->{_hex_parts} }; $hex_part_i++ ){
        my $hex_part = $self->{_hex_parts}->[$hex_part_i];

        my $start_addr = $hex_part->[0];
        my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

        my $cur_high_addr_hex = '0000';

        for ( my $slice_i = 0; $slice_i * $bytes_hex_a_line < @{$hex_part->[1]}; $slice_i++ ){
            my $total_addr = $start_addr + $slice_i*$bytes_hex_a_line;

            my ($addr_high_hex, $addr_low_hex) = unpack '(A4)*', sprintf( '%08X', $total_addr );

            if ( $cur_high_addr_hex ne $addr_high_hex ){
                $cur_high_addr_hex = $addr_high_hex;
                $intel_hex_string .=  _intel_hex_line_of( '0000', 4, [ unpack '(A2)*', $cur_high_addr_hex ] );
            }

            if ( ($slice_i + 1) * $bytes_hex_a_line <=  $#{$hex_part->[1]}){
                $intel_hex_string .= _intel_hex_line_of(
                    $addr_low_hex, 0,
                    [ @{$hex_part->[1]}[ $slice_i * $bytes_hex_a_line .. ($slice_i + 1) * $bytes_hex_a_line - 1 ] ]
                );
            }
            else {
                $intel_hex_string .= _intel_hex_line_of(
                    $addr_low_hex, 0, [ @{$hex_part->[1]}[ $slice_i * $bytes_hex_a_line .. $#{$hex_part->[1]} ] ]
                );
            }
        }
    }
                               # intel hex eof
    return $intel_hex_string . ":00000001FF\n";
}

sub _intel_hex_line_of {
    my ( $addr_low_hex, $type, $bytes_hex_ref ) = @_;

    my $byte_count = defined $bytes_hex_ref ? scalar @$bytes_hex_ref : 0;

    my $sum = 0;
    $sum += $_ for ( $byte_count, (map { hex $_ } unpack '(A2)*', $addr_low_hex),
                     $type, (map { hex $_ } @$bytes_hex_ref) );

    #convert to hex, take lsb
    $sum = substr( sprintf( '%02X', $sum ), -2 );

    my $checksum_hex = sprintf '%02X', ( hex $sum ^ 255 ) + 1;
    $checksum_hex    = '00' if length $checksum_hex != 2;

    return join '',
        (':',
         sprintf( '%02X', $byte_count ),
         $addr_low_hex,
         sprintf( '%02X', $type ),
         @$bytes_hex_ref,
         $checksum_hex,
         "\n"
     );
}

sub as_srec_hex {
    my ($self, $bytes_hex_a_line) = @_;

    my $srec_hex_string = '';
    for ( my $hex_part_i = 0; $hex_part_i < @{ $self->{_hex_parts} }; $hex_part_i++ ){
        my $hex_part = $self->{_hex_parts}->[$hex_part_i];

        my $start_addr = $hex_part->[0];
        my $end_addr   = $hex_part->[0] + $#{$hex_part->[1]};

        for ( my $slice_i = 0; $slice_i * $bytes_hex_a_line < @{$hex_part->[1]}; $slice_i++ ){
            my $total_addr = $start_addr + $slice_i*$bytes_hex_a_line;

            if ( ($slice_i + 1) * $bytes_hex_a_line <=  $#{$hex_part->[1]}){
                $srec_hex_string .= _srec_hex_line_of(
                    $total_addr,
                    [ @{$hex_part->[1]}[ $slice_i * $bytes_hex_a_line .. ($slice_i + 1) * $bytes_hex_a_line - 1 ] ]
                );
            }
            else {
                $srec_hex_string .= _srec_hex_line_of(
                    $total_addr,
                    [ @{$hex_part->[1]}[ $slice_i * $bytes_hex_a_line .. $#{$hex_part->[1]} ] ]
                );
            }
        }
    }

    return $srec_hex_string;
}

sub _srec_hex_line_of {
    my ( $total_addr, $bytes_hex_ref ) = @_;

    my $total_addr_hex = sprintf '%04X', $total_addr;

    my $type;
    # 16 bit addr
    if ( length $total_addr_hex == 4 ){
        $type = 1;
    }
    # 24 bit addr
    elsif ( length $total_addr_hex <= 6 ){
        $total_addr_hex = "0$total_addr_hex" if length $total_addr == 5;
        $type = 2;
    }
    # 32 bit addr
    elsif ( length $total_addr_hex <= 8 ){
        $total_addr_hex = "0$total_addr_hex" if length $total_addr == 7;
        $type = 3;
    }
    else {
        die "$total_addr_hex to big for 32 bit address";
    }

    # count of data bytes + address bytes
    my $byte_count = defined $bytes_hex_ref ? scalar @$bytes_hex_ref : 0;
    $byte_count   += length( $total_addr_hex ) / 2;

    my $sum = 0;
    $sum += $_ for ( $byte_count,
                     (map { hex $_ } unpack '(A2)*', $total_addr_hex),
                     (map { hex $_ } @$bytes_hex_ref) );

    #convert to hex, take lsb
    $sum = substr( sprintf( '%02X', $sum ), -2 );

    my $checksum_hex = sprintf '%02X', (hex $sum ^ 255);
    $checksum_hex    = '00' if length $checksum_hex != 2;

    return join '',
        ("S$type",
         sprintf( '%02X', $byte_count),
         $total_addr_hex,
         @$bytes_hex_ref,
         $checksum_hex,
         "\n"
     );
}

# used to set parts, hex_parts_ref is sorted
sub _set_merged_parts {
    my ( $self, $hex_parts_ref ) = @_;

    return unless @$hex_parts_ref;

    # set first part
    my @merged_parts          = shift @$hex_parts_ref;
    #my $merged_parts_end_addr = $merged_parts[-1]->[0] + $#{ $merged_parts[-1]->[1] };
    my $merged_parts_end_addr = $merged_parts[-1]->[0] + @{ $merged_parts[-1]->[1] };

    for my $hex_part_ref (@$hex_parts_ref) {

        my $hex_part_start_addr = $hex_part_ref->[0];
        my $hex_part_byte_count = @{ $hex_part_ref->[1] };
        my $hex_part_end_addr   = $hex_part_start_addr + $hex_part_byte_count;

        # overwrite?
        if ( $hex_part_start_addr < $merged_parts_end_addr ) {
            # remove parts completly inlcuded
            my $warning = "colliding parts: ";

            while( $hex_part_start_addr < $merged_parts[-1]->[0] ){
                my $removed_part = pop @merged_parts;
                $warning .= $removed_part->[0] . ' .. ' . $removed_part->[0] +  @{$removed_part->[1]} . ', ';
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
        elsif ( $hex_part_start_addr == $merged_parts_end_addr ) {
            push @{ $merged_parts[-1]->[1] }, @{ $hex_part_ref->[1] };
        }

        #new part!
        else {
            push @merged_parts, $hex_part_ref;
        }

        #set new addr
        $merged_parts_end_addr = $hex_part_end_addr if $hex_part_end_addr > $merged_parts_end_addr;
    }

    $self->{_hex_parts} = \@merged_parts;

    return;
}

1;

=head1 NAME

Hex::Record - manipulate intel and srec hex records

=head1 SYNOPSIS

    use Hex::Record::Parser qw(parse_intel_hex parse_srec_hex);

    # get hex object from the parser
    my $hex_record = parse_intel_hex( $intel_hex_record_as_string );

    # get 100 bytes ( hex format ) starting at address 0x100
    # every single byte that is not found is returned as undef
    my $bytes_ref = $hex->get( 0x100, 10 );

    # remove 100 bytes starting at address 0x100
    $hex_record->remove( 0x100, 10 );

    # write/overwrite 3 bytes starting at address 0x100
    $hex_record->write( 0x100, [ 'AA', 'BB', 'CC' ] );

    # dump as intel hex ( will use extended linear addresses for offset )
    # maximum of 10 bytes in data field
    my $intel_hex_string = $hex_record->as_intel_hex(10);

    # dump as srec hex ( always tries to use smallest address )
    # maximum of 10 bytes in data field
    my $srec_hex_string = $hex_record->as_screc_hex(10);

=head1 DESCRIPTION

Manipulate intel/srec hex files.

=head2 Methods of Hex

=over 12

=item C<get( $from, $count )>

Returns $count hex bytes in array reference starting at address $from.
If hex byte is not found, undef instead.

    [ 'AA', '00', undef, undef, 'BC', undef ]

=item C<remove( $from, $count )>

Removes $count bytes starting at address $from.

=item C<write( $from, $bytes_ref )>

(Over)writes bytes starting at address $from with bytes in $bytes_ref.

=item C<as_intel_hex( $bytes_hex_a_line )>

Returns a string containing hex bytes formated as intel hex.
Extended linear addresses as offset are used if needed.
Extended segment addresses are not supported.

=item C<as_srec_hex( $bytes_hex_a_line )>

Returns a string containing hex bytes formated as srec hex.
Maximum of $hytes_hex_a_line in data field.
Tries to use the smallest address field.

=back

=head1 LICENSE

This is released under the Artistic License.

=head1 AUTHOR

spebern <bernhard@specht.net>

=cut
