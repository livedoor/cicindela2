package Cicindela::Filters::InverseUserFrequency;

# $Id: InverseUserFrequency.pm 8 2008-12-23 20:52:26Z tsukue $
#
# ratings を上書き変更するんじゃなくて、iuf のテーブルを別に作って item_id - iuf の対応を覚えさせておくタイプ

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table {
    shift->{in_table} || 'extracted_picks'; # fields: id, user_id, item_id
}

sub out_table {
    shift->{out_table} || 'iuf' ; # fields: item_id, iuf
}

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %&out_table (
   item_id int not null primary key,
   iuf double
) engine = memory
},
        'cleanup' => q{truncate table %&out_table},

        'calc_iuf' => q{
insert into %&out_table (item_id, iuf)
select a.item_id, log(b.total / a.cnt) / log(?) from
  (select item_id, count(*) cnt from %&in_table group by item_id) a,
  (select count(distinct user_id) total from %&in_table) b
},
    };
}

##

sub process {
    my $self = shift;

    my $log_base = $self->{log_base} || 2;

    $self->cleanup;
    $self->sql('calc_iuf')->execute($log_base) or db_error;
}


1;
