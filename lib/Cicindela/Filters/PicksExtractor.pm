package Cicindela::Filters::PicksExtractor;

# $Id: PicksExtractor.pm 8 2008-12-23 20:52:26Z tsukue $
#
# ItemSimilarties など、重い統計処理用に、picks /ratings の一部データのみメモリテーブルにコピーする系。
# picks(ratings) から読み出して extracted_picks(extracted_ratings) に出力する。
#
# これはユーザがそのアイテムを選択したかしないかの2値のみ(☆レーティングはない)タイプ
# レーティング付きは ::WithRatings 子クラスで。

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table {
    shift->{in_table} || 'picks'; # fields: id, user_id, item_id, timestamp
}

sub out_table {
    shift->{out_table} || 'extracted_picks'; # fields: id, user_id, item_id
}

sub lock_tables {
    my $self = shift;

    return [
        [ $self->in_table, 'read' ],
        [ $self->in_table . ' as b', 'read' ],
        [ $self->out_table, 'write' ],
    ];
}

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %&out_table (
  user_id int not null,
  item_id int not null,

  unique (item_id, user_id),
  key using hash (item_id),
  key using hash (user_id)
) engine = memory
},

        'cleanup' => q{truncate table %&out_table},

        # 一定期間内のpickで、選択者数の多いアイテムの中からサンプルを取得する
        'extract_recent_set' => q{
insert ignore into %&out_table (user_id, item_id)
select b.user_id, b.item_id from
  (select item_id, count(*) cnt from %&in_table where timestamp > date_sub(now(), interval %$interval) group by item_id having cnt >= ?) a,
  %&in_table b
  where a.item_id = b.item_id and b.timestamp > date_sub(now(), interval %$interval)
  order by b.timestamp desc
  limit ?
},

        # 一定期間より前のpickで、選択者数の多いアイテムの中からサンプルを取得する(↑とペアで使う用)
        'extract_older_set' => q{
insert ignore into %&out_table (user_id, item_id)
select b.user_id, b.item_id from
  (select item_id, count(*) cnt from %&in_table where timestamp <= date_sub(now(), interval %$interval) group by item_id having cnt >= ?) a,
  %&in_table b
  where a.item_id = b.item_id and b.timestamp <= date_sub(now(), interval %$interval)
  order by b.timestamp desc
  limit ?
},

        # ライトユーザを避けてサンプルを取得する。
        'extract_heavy_user_set' => q{
insert ignore into %&out_table (user_id, item_id)
select b.user_id, b.item_id from
  (select user_id, count(*) cnt from %&in_table group by user_id having cnt between ? and ?) a,
  %&in_table b
  where a.user_id = b.user_id
  order by b.timestamp desc limit ?
},

        # 単純に新しい順にn件を利用する。
        'extract_simple_set' => q{
insert ignore into %&out_table (user_id, item_id)
  select user_id, item_id from %&in_table order by timestamp desc limit ?
},


    };
}

sub process {
    my $self = shift;

    $self->cleanup;

    $self->lock_on;

    ($self->{use_heavy_user_set} and $self->_extract_heavy_user_set)
        or ($self->{use_simple_set} and $self->_extract_simple_set)
        or ($self->_extract_recent_and_older_set);

    $self->lock_off;
}

sub _extract_recent_and_older_set {
    my $self = shift;

#    my $interval = $self->{interval} || '3 month';
    $self->{interval} ||= '3 month'; ## for %$interval

    my $use_recent_set = defined($self->{use_reccent_set}) ? $self->{use_recent_set} : 1;
    my $threshold1 = $self->{threshold1} || 3;
    my $limit1 = $self->{limit1} || 250000;

    my $use_older_set = defined($self->{use_older_set}) ? $self->{use_older_set} : 1;
    my $threshold2 = $self->{threshold2} || 5;
    my $limit2 = $self->{limit2} || 250000;

    if ($use_recent_set) {
        $self->sql('extract_recent_set')->execute(
                   $threshold1, $limit1
               ) or db_error;
    }

    if ($use_older_set) {
        $self->sql('extract_older_set')->execute(
                   $threshold2, $limit2
               ) or db_error;
    }
}

sub _extract_heavy_user_set {
    my $self = shift;

    my $threshold_min = $self->{threshold_min} || 5;
    my $threshold_max = $self->{threshold_max} || 50;
    my $limit = $self->{limit} || 500000;

    $self->sql('extract_heavy_user_set')->execute(
        $threshold_min, $threshold_max, $limit,
    ) or db_error;
}

sub _extract_simple_set {
    my $self = shift;

    my $limit = $self->{limit} || 500000;
    $self->sql('extract_simple_set')->execute($limit) or db_error;
}

1;
