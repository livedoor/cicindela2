package Cicindela::Recommender::UserSimilarities::WithRatings;

# $Id: WithRatings.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::UserSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

# RatingsConverter を使ってる場合は，in_table_user にも convert 後のレートを使った方が良い
sub in_table_user { shift->{in_table_user} || 'converted_ratings_online' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'recommend_for_user' => q{
select result.item_id, result.score
  from
  (select u.item_id item_id, %&scoring score
    from (select user_id2, score from %&in_table where user_id1 = ?) s,
      %&in_table_user u
    where u.user_id = s.user_id2
    group by u.item_id
    order by u.rating desc
--    order by score desc
    limit ?
  ) result
  %&_omit_uninterested
  order by result.score desc
  limit ?
},

    };
}

sub scoring {
    my $self = shift;

    return $self->{scoring} || q{avg(u.rating * s.score) * log(count(*)+1)};
#    return $self->{scoring} || q{avg(u.rating * s.score)};
#    return $self->{scoring} || q{sum(u.rating * s.score)};
#    return $self->{scoring} || q{sum(u.rating * s.score)/sum(sign(s.score) * s.score)};
}

1;
