use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bencode',
    license             => 'perl',
    dist_author         => 'Aristotle Pagaltzis <pagaltzis@gmx.de>',
    dist_version_from   => 'lib/Bencode.pm',
    requires => {
        'Test::More'   => 0,
        'Scalar::Util' => 0,
    },
    add_to_cleanup      => [ 'Bencode-*' ],
	create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
