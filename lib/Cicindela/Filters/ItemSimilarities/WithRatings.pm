package Cicindela::Filters::ItemSimilarities::WithRatings;

# $Id: WithRatings.pm 8 2008-12-23 20:52:26Z tsukue $
#
# ItemSimilarities のレーティング付き版

use strict;
use base qw(Cicindela::Filters::ItemSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'extracted_ratings' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'insert_item_similarities' => q{
insert into %&out_table (item_id1, item_id2, score)
select ?, items.item_id,
    items.score
%$_count_commentout  * (log(items.count) / ?)
%$_iuf_commentout  * coalesce(iuf.iuf, 1)
    score
  from
  (select r2.item_id item_id, count(*) count,
      coalesce(sum(r1.rating * r2.rating) / (sqrt(sum(r1.rating * r1.rating))*sqrt(sum(r2.rating * r2.rating))), 0) score
    from %&in_table r1, %&in_table r2
    where r1.item_id = ?
      and r2.user_id = r1.user_id
      and r2.item_id != ?
    group by r2.item_id
    having count >= ?
  ) items
%$_iuf_commentout   left outer join %&in_table_iuf iuf on items.item_id = iuf.item_id
  order by %&order_by
  limit ?
},
    };
}

1;
