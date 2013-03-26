package Cicindela::Recommender::ItemSimilarities::WithRatings;

# $Id: WithRatings.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::ItemSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

# RatingsConverter を使ってる場合は，in_table_user にも convert 後のレートを使った方が良い
sub in_table_user { shift->{in_table_user} || 'converted_ratings_online' }

sub scoring {
    my $self = shift;

    return $self->{scoring} || q{avg(r.rating * s.score) * log(count(*)+1)};
#    return $self->{scoring} || q{avg(r.rating * s.score)};
#    return $self->{scoring} || q{sum(r.rating * s.score)};
#    return $self->{scoring} || q{sum(r.rating * s.score)/sum(sign(s.score) * s.score)};
}


1;
