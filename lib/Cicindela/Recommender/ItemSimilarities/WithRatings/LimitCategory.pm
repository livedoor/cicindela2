package Cicindela::Recommender::ItemSimilarities::WithRatings::LimitCategory;

# $Id: LimitCategory.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::ItemSimilarities::LimitCategory Cicindela::Recommender::ItemSimilarities::WithRatings);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

1;
