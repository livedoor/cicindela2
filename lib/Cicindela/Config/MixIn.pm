package Cicindela::Config::MixIn;
use base qw(Exporter);
use Cicindela::Config;
our @EXPORT = qw(config);

sub config { Cicindela::Config->instance; }

1;
