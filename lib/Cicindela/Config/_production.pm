package Cicindela::Config::_production;
use strict;
use vars qw(%C);
*Config = \%C;

=pod

you can override configurations set in _common.pm with the ones defined in this file
by creating an executable file '/etc/Cicindela-conf.pl' with the following content:

#!/usr/bin/perl
$ENV{CICINDELA_CONFIG_NAME} = '_production';
1;

=cut

1;
