use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Bencode',
	license             => 'perl',
	dist_author         => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
	requires            => { 'perl' => '5.6.1', },
	build_requires      => { 'Test::More' => 0, },
	add_to_cleanup      => [ 'Bencode-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
