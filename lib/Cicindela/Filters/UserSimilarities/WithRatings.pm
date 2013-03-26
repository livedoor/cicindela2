package Cicindela::Filters::UserSimilarities::WithRatings;

# $Id: WithRatings.pm 8 2008-12-23 20:52:26Z tsukue $
#
# UserSimilarities のレーティング付き版

use strict;
use base qw(Cicindela::Filters::UserSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'extracted_ratings' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'insert_user_similarities' => q{
insert into %&out_table (user_id1, user_id2, score)
select ?, users.user_id, users.score from (
  select r2.user_id user_id, count(*) count,
      coalesce(sum(r1.rating * r2.rating) / (sqrt(sum(r1.rating * r1.rating))*sqrt(sum(r2.rating * r2.rating))), 0)
%$_count_commentout  * (log(count(*)) / ?)
%$_iuf_commentout  * coalesce(iuf.iuf, 1)
      score
    from %&in_table r1, %&in_table r2
%$_iuf_commentout , %&in_table_iuf iuf
    where r1.user_id = ?
      and r2.item_id = r1.item_id
      and r2.user_id != ?
%$_iuf_commentout and iuf.item_id = r1.item_id
    group by r2.user_id
    having count(*) >= ?
  ) users
  order by %&order_by
  limit ?
},
    };
}

1;
