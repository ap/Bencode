package Bencode;

=head1 NAME

Bencode - BitTorrent serialisation format


=head1 VERSION

This document describes Bencode version 1.0


=head1 SYNOPSIS

    use Bencode qw( bencode bdecode );
    
	my $bencoded = bencode { 'age' => 25, 'eyes' => 'blue' };
	print $bencoded, "\n";
	my $decoded = bdecode $bencoded;


=head1 DESCRIPTION

This module implements the BitTorrent I<bencode> serialisation formation as described in L<http://www.bittorrent.org/protocol.html>.


=head1 INTERFACE 

=head2 C<bencode( $datastructure )>

Takes a single argument which may be a scalar or a reference to a scalar, array or hash. Arrays and hashes may in turn contain values of these same types. Simple scalars that look like canonically represented integers will be serialised as such. To bypass the heuristic and force serialisation as a string, use a reference to a scalar.

Croaks on unhandled data types.

=head2 C<bdecode( $string )>

Takes a string and returns the corresponding deserialised data structure.

Croaks on malformed data.

=head1 DIAGNOSTICS

=over

=item C<trailing garbage at %s>

Your data does not end after the first I<bencode>-serialised item.

=item C<garbage at %s>

Your data is malformed, including a string length greater than the length of the available data.

=item C<unexpected end of data at %s>

Your data is truncated.

=item C<dict key not in sort order at %s>

Your data violates the I<bencode> format constaint that dict keys must appear in lexical sort order.

=item C<duplicate dict key at %s>

Your data violates the I<bencode> format constaint that all dict keys must be unique.

=item C<dict key is not a string at %s>

Your data violates the I<bencode> format constaint that all dict keys be strings.

=item C<unhandled data type>

=back


=head1 BUGS AND LIMITATIONS

Strings and numbers are practically indistinguishable in Perl, so C<bencode()> has to resort to heuristic to decide which to use. This cannot be fixed.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-bencode@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Aristotle Pagaltzis  L<mailto:pagaltzis@gmx.de>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Aristotle Pagaltzis. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

use strict;

our $VERSION = '1.0';

use Carp;
use Exporter qw( import );

our @EXPORT_OK = qw( bencode bdecode );

our $DEBUG = 0;

sub _msg { sprintf "@_", defined pos() ? pos() : -1 }

sub _bdecode_chunk {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;

	carp _msg 'decoding at %s' if $DEBUG;

	my ( $q, $r ); # can't declare 'em inline because of qr//-as-closure
	my $str_rx = qr/ \G ( 0 | [1-9] \d* ) : ( (??{
		# workaround: can't use quantifies > 32766 in patterns,
		# so for eg. 65536 chars produce something like '(?s).{32766}.{32766}.{4}'
		$q = int( $^N \/ 32766 );
		$r = $^N % 32766;
		$q--, $r += 32766 if $q and not $r;
		"(?s)" . ( ".{32766}" x $q ) . ".{$r}"
	}) ) /x;

	if( m/$str_rx/xgc ) {
		carp _msg STRING => "(length $1)", $1 < 200 ? "[$2]" : () if $DEBUG;
		return $2;
	}
	elsif( m/ \G i ( 0 | -? [1-9] \d* ) e /xgc ) {
		carp _msg INTEGER => $1 if $DEBUG;
		return $1;
	}
	elsif( m/ \G l /xgc ) {
		carp _msg 'LIST' if $DEBUG;
		my @list;
		until( m/ \G e /xgc ) {
			carp _msg 'list not terminated at %s, looking for another element' if $DEBUG;
			push @list, _bdecode_chunk();
		}
		return \@list;
	}
	elsif( m/ \G d /xgc ) {
		carp _msg 'DICT' if $DEBUG;
		my $last_key;
		my %hash;
		until( m/ \G e /xgc ) {
			carp _msg 'dict not terminated at %s, looking for another pair' if $DEBUG;

			# some copy-paste code reuse here...
			# just too little gain from further abstraction,
			# and marginally more speed without it
			m/$str_rx/xgc or croak _msg 'dict key is not a string at %s';
			carp _msg STRING => "(length $1)", $1 < 200 ? "[$2]" : () if $DEBUG;

			my $key = $2;

			croak _msg 'duplicate dict key at %s' if exists $hash{ $key };
			croak _msg 'dict key not in sort order at %s' if defined $last_key and $key lt $last_key;

			$last_key = $key;
			$hash{ $key } = _bdecode_chunk();
		}
		return \%hash;
	}
	else {
		croak _msg m/ \G \z /xgc ? 'unexpected end of data at %s' : 'garbage at %s';
	}
}

sub bdecode {
	croak 'no arguments passed' if not @_;
	croak 'more than one argument' if @_ > 1;
	local $_ = shift;
	my $data = _bdecode_chunk();
	croak _msg 'trailing garbage at %s' if $_ !~ m/ \G \z /xgc;
	return $data;
}

sub _bencode {
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	my ( $data ) = @_;
	if( not ref $data ) {
		return sprintf 'i%se', $data if $data =~ m/\A (?: 0 | -? [1-9] \d* ) \z/x;
		return length( $data ) . ':' . $data;
	}
	elsif( ref $data eq 'SCALAR' ) {
		# escape hatch -- use this to avoid num/str heuristics
		return length( $$data ) . ':' . $$data;
	}
	elsif( ref $data eq 'ARRAY' ) {
		return 'l' . join( '', map _bencode( $_ ), @$data ) . 'e';
	}
	elsif( ref $data eq 'HASH' ) {
		return 'd' . join( '', map { _bencode( \$_ ), _bencode( $data->{ $_ } ) } sort keys %$data ) . 'e';
	}
	else {
		croak 'unhandled data type';
	}
}

sub bencode {
	croak 'no arguments passed' if not @_;
	croak 'more than one argument' if @_ > 1;
	# just to make the CarpLevel gymnastics correct
	&_bencode;
}

bdecode( 'i1e' );
