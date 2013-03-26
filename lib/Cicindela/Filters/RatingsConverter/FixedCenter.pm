package Cicindela::Filters::RatingsConverter::FixedCenter;

# $Id: FixedCenter.pm 8 2008-12-23 20:52:26Z tsukue $
#
# レーティング3が中心とか決まっている場合など用

use strict;
use base qw(Cicindela::Filters::RatingsConverter);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'process' => qq{
update %&table set rating = (rating - ?) / ?
},
    };
}

sub set_args {
    my $self = shift;

    my $center = $self->{center} || 3;
    my $factor = $self->{factor} || 2;
    return ($center, $factor);
}

1;
