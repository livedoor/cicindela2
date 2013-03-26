package Cicindela::Config::_test;
use strict;
use vars qw(%C);
*Config = \%C;

=pod

you can override configurations set in _common.pm with the ones defined in this file
by creating an executable file '/etc/Cicindela-conf.pl' with the following content:

#!/usr/bin/perl
$ENV{CICINDELA_CONFIG_NAME} = '_test';
1;

=cut

$C{DEBUG} = 1;
$C{IS_TEST} = 1;

1;
