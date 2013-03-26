package Cicindela::Filters::UserSimilarities;

# $Id: UserSimilarities.pm 8 2008-12-23 20:52:26Z tsukue $
#
# 見た/見ない, ブックマークした/しない など、1/0 のみで☆レーティングのないデータにおける user間類似度

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'extracted_picks' }
sub in_table_iuf { shift->{in_table_iuf} || 'iuf' }
sub out_table { shift->{out_table} || 'user_similarities' }
sub out_table_online { shift->out_table . '_online' }

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %$_current_table (
   user_id1 int not null,
   user_id2 int not null,
   score double,

   unique (user_id1, user_id2),
   key using hash (user_id1)
) engine = memory
},

        'cleanup' => q{truncate table %&out_table},

        'for_each_user_id' => q{
select distinct user_id from %&in_table
},

        'insert_user_similarities' => q{
insert into %&out_table (user_id1, user_id2, score)
select ?, users.user_id, users.score from (
  select r2.user_id, count(*) count, (log(count(*)) / ?)
%$_iuf_commentout * coalesce(iuf.iuf, 1)
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

    my $use_iuf = defined($self->{use_iuf}) ? $self->{use_iuf} : 1;
    $self->{_iuf_commentout} = $use_iuf ? '' : '--';

    my $log_base = $self->{log_base} || 2;
    my $log = log($log_base);

    $self->cleanup;

    my $sth = $self->sql('for_each_user_id');
    $sth->execute or db_error;
    while (my ($user_id) = $sth->fetchrow_array) {
        $self->sql('insert_user_similarities')->execute(
            $user_id, $log, $user_id, $user_id, $threshold, $limit
        ) or db_error;
    }
    $sth->finish;
}

sub order_by {
    my $self = shift;

    return $self->{order_by} || q{users.count desc, score desc};
    return $self->{order_by} || q{log(users.count)/log(10) * abs(users.score) desc};
}


1;
