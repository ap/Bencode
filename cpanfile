requires 'perl', '5.006';
requires 'strict';
requires 'warnings';
requires 'Exporter::Tidy';

on test => sub {
	requires 'Test::Differences';
	requires 'Test::More', '0.88';
};

# vim: ft=perl
