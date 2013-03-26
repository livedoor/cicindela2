package Cicindela::Filters::CopyPicks;

# $Id: CopyPicks.pm 8 2008-12-23 20:52:26Z tsukue $
#
# まず最初にオリジナルの picks を集計用にコピーする系。picks (またはratings) への出力をする。
#
# RatingsConverter::* は extracted_ratings ではなく ratings 全体に
# 適用しておく必要がある場合がある。
# (Recommender::recommend_for_user でユーザ毎の変換後のレーティングを利用する場合)
# なので，おおもとの ratings は ratings は変更せずにおいといて，そこから毎回コピーして使う。

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'picks' }
sub out_table { shift->{out_table} || 'converted_picks' }
sub out_table_online { shift->out_table . '_online' }

sub out_table_engine { shift->{out_table_engine} || 'innodb' } # ここで作ったテーブルを(PicksExtracotrを通さず)そのままItemSimilartiesなどにつかうのなら 'memory' のほうがいい。

sub lock_tables {
    my $self = shift;

    return [
        [ $self->in_table, 'read' ],
        [ $self->out_table, 'write' ],
    ];
}

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %$_current_table (
  item_id int not null,
  user_id int not null,
  timestamp timestamp not null default current_timestamp,

  unique key (user_id, item_id),
  key (item_id),
  key (user_id, timestamp)
) engine = %&out_table_engine
},

        'cleanup' => q{truncate table %&out_table},

        'process' => q{
insert into %&out_table (item_id, user_id, timestamp)
  select item_id, user_id, timestamp from %&in_table
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

    $self->cleanup;
    $self->lock_on;
    $self->sql('process')->execute or db_error;
    $self->lock_off;
}


1;
