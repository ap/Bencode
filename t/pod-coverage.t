#!perl -T

use Test::More;
eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
plan skip_all => 'Set the POD_TESTS environment variable to run these tests' if not exists $ENV{POD_TESTS};
all_pod_coverage_ok();

# vim:ft=perl:
