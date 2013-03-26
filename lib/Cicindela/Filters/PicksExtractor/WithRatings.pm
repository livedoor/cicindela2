package Cicindela::Filters::PicksExtractor::WithRatings;

# $Id: WithRatings.pm 8 2008-12-23 20:52:26Z tsukue $
#
# ユーザがそれぞれのアイテムにレートをつけるタイプ。

use strict;
use base qw(Cicindela::Filters::PicksExtractor);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table {
    shift->{in_table} ||  'ratings'; # fields: id, user_id, item_id, rating, timestamp
}

sub out_table {
    shift->{out_table} || 'extracted_ratings'; # fields: id, user_id, item_id, rating
}

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'create_table' => q{
create table if not exists %&out_table (
  user_id int not null,
  item_id int not null,
  rating double,

  unique (item_id, user_id),
  key using hash (item_id),
  key using hash (user_id)
) engine = memory
},

        'extract_recent_set' => q{
insert into %&out_table (user_id, item_id, rating)
select b.user_id, b.item_id, b.rating from
  (select item_id, count(*) cnt from %&in_table where timestamp > date_sub(now(), interval %$interval) group by item_id having cnt >= ?) a,
  %&in_table b
  where a.item_id = b.item_id and b.timestamp > date_sub(now(), interval %$interval)
  order by b.timestamp desc
  limit ?
},

        'extract_older_set' => q{
insert ignore into %&out_table (user_id, item_id, rating)
select b.user_id, b.item_id, b.rating from
  (select item_id, count(*) cnt from %&in_table where timestamp <= date_sub(now(), interval %$interval) group by item_id having cnt >= ?) a,
  %&in_table b
  where a.item_id = b.item_id and b.timestamp <= date_sub(now(), interval %$interval)
  order by b.timestamp desc
  limit ?
},

        # ライトユーザを避けてサンプルを取得する。
        'extract_heavy_user_set' => q{
insert ignore into %&out_table (user_id, item_id, rating)
select b.user_id, b.item_id, b.rating from
  (select user_id, count(*) cnt from %&in_table group by user_id having cnt between ? and ?) a,
  %&in_table b
  where a.user_id = b.user_id
  order by b.timestamp desc limit ?
},

        # 単純に新しい順にn件を利用する。
        'extract_simple_set' => q{
insert ignore into %&out_table (user_id, item_id, rating)
  select user_id, item_id, rating from %&in_table order by timestamp desc limit ?
},



    };
}


1;
