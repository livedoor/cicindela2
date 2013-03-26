package Cicindela::Filters::RatingsConverter::ZScore;

# $Id: ZScore.pm 8 2008-12-23 20:52:26Z tsukue $
#
# zscore

use strict;
use base qw(Cicindela::Filters::RatingsConverter);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'process' => q{
update %&table r,
    (select user_id, avg(rating) avg, stddev_pop(rating) stddev from %&table group by user_id) avgs
  set r.rating = (case when avgs.stddev > 0 then (r.rating - avgs.avg) / avgs.stddev else 0 end)
  where r.user_id = avgs.user_id
},
    };
}


1;
