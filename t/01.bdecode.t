use Test::More;

use Bencode qw( bdecode );

my @test = (
	'0:0:'                     => \'data past end of first correct bencoded string',
	'ie'                       => \'empty integer',
	'i341foo382e'              => \'malformed integer',
	'i4e'                      => 4,
	'i0e'                      => 0,
	'i123456789e'              => 123456789,
	'i-10e'                    => -10,
	'i-0e'                     => \'negative zero integer',
	'i123'                     => \'unterminated integer',
	''                         => \'empty string',
	'i6easd'                   => \'integer with trailing garbage',
	'35208734823ljdahflajhdf'  => \'garbage looking vaguely like a string, with large count',
	'2:abfdjslhfld'            => \'string with trailing garbage',
	'0:'                       => '',
	'3:abc'                    => 'abc',
	'10:1234567890'            => '1234567890',
	'02:xy'                    => \'string with extra leading zero in count',
	'l'                        => \'unclosed empty list',
	'le'                       => [],
	'leanfdldjfh'              => \'empty list with trailing garbage',
	'l0:0:0:e'                 => [ '', '', '' ],
	'relwjhrlewjh'             => \'complete garbage',
	'li1ei2ei3ee'              => [ 1, 2, 3 ],
	'l3:asd2:xye'              => [ 'asd', 'xy' ],
	'll5:Alice3:Bobeli2ei3eee' => [ [ 'Alice', 'Bob' ], [ 2, 3 ] ],
	'd'                        => \'unclosed empty dict',
	'defoobar'                 => \'empty dict with trailing garbage',
	'de'                       => {},
	'd3:agei25e4:eyes4:bluee'  => { 'age' => 25, 'eyes' => 'blue' },
	'd8:spam.mp3d6:author5:Alice6:lengthi100000eee' => { 'spam.mp3' => { 'author' => 'Alice', 'length' => 100000 } },
	'd3:fooe'                  => \'dict with odd number of elements',
	'di1e0:e'                  => \'dict with integer key',
	'd1:b0:1:a0:e'             => \'missorted keys',
	'd1:a0:1:a0:e'             => \'duplicate keys',
	'i03e'                     => \'integer with leading zero',
	'l01:ae'                   => \'list with string with leading zero in count',
	'9999:x'                   => \'string shorter than count',
	'l0:'                      => \'unclosed list with content',
	'd0:0:'                    => \'unclosed dict with content',
	'd0:'                      => \'unclosed dict with odd number of elements',
	'00:'                      => \'zero-length string with extra leading zero in count',
	'l-3:e'                    => \'list with negative-length string',
	'i-03e'                    => \'negative integer with leading zero',
);

plan tests => 0 + @test / 2;

while ( my ( $frozen, $thawed ) = splice @test, 0, 2 ) {
	my $result = eval { bdecode( $frozen ) };
	ref $thawed ne 'SCALAR'
		? is_deeply( $result, $thawed, "decode '$frozen'" )
		: ok( $@, "reject $$thawed" );
}

# vim: set ft=perl:
