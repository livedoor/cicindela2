package Cicindela::Filters::ItemSimilarities;

# $Id: ItemSimilarities.pm 8 2008-12-23 20:52:26Z tsukue $
#
# 見た/見ない, ブックマークした/しない など、1/0 のみで☆レーティングのないデータにおける item間類似度

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'extracted_picks' }
sub in_table_iuf { shift->{in_table_iuf} || 'iuf' }
sub out_table { shift->{out_table} || 'item_similarities' }
sub out_table_online { shift->out_table . '_online' }

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %$_current_table (
   item_id1 int not null,
   item_id2 int not null,
   score double,

   unique (item_id1, item_id2),
   key using hash (item_id1)
) engine = memory
},

        'cleanup' => q{truncate table %&out_table},

        'for_each_item_id' => q{
select distinct item_id from %&in_table
},

        'insert_item_similarities' => q{
insert into %&out_table (item_id1, item_id2, score)
select ?, items.item_id,
    (log(items.count) / ?)
%$_iuf_commentout  * coalesce(iuf.iuf, 1)
    score
  from
  (select r2.item_id item_id, count(*) count
    from %&in_table r1, %&in_table r2
    where r1.item_id = ?
      and r2.user_id = r1.user_id
      and r2.item_id != ?
    group by r2.item_id
    having count >= ?
  ) items
%$_iuf_commentout  left outer join %&in_table_iuf iuf on items.item_id = iuf.item_id
  order by %&order_by
  limit ?
},
    };
}

sub create_tables {
    my $self = shift;
    for ($self->out_table, $self->out_table_online) {
        $self->{_current_table} = $_;
        $self->sql('create_table')->execute or db_error;
        delete $self->{_current_table};
    }
}

sub online_swaps {
    my $self = shift;

    return [$self->out_table, $self->out_table_online];
}

##

sub process {
    my $self = shift;

    my $threshold = $self->{threshold} || 3;
    my $limit = $self->{limit} || 30;

    my $use_counts = defined($self->{use_counts}) ? $self->{use_counts} : 1;
    $self->{_count_commentout} = $use_counts ? '' : '--';

    my $use_iuf = defined($self->{use_iuf}) ? $self->{use_iuf} : 1;
    $self->{_iuf_commentout} = $use_iuf ? '' : '--';

    my $log_base = $self->{log_base} || 2;
    my $log = log($log_base);

    $self->cleanup;

    my $sth = $self->sql('for_each_item_id');
    $sth->execute or db_error;
    while (my ($item_id) = $sth->fetchrow_array) {
        $self->sql('insert_item_similarities')->execute(
            $item_id, $log, $item_id, $item_id, $threshold, $limit
        ) or db_error;
    }
    $sth->finish;
}

sub order_by {
    my $self = shift;

    return $self->{order_by} || q{items.count desc, score desc};
#    return $self->{order_by} || q{log(items.count) * abs(score) desc};
}


1;
