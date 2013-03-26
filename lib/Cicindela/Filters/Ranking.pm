package Cicindela::Filters::Ranking;

# $Id: Ranking.pm 8 2008-12-23 20:52:26Z tsukue $
#
# simple ranking

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table {
    shift->{in_table} || 'extracted_picks'; # fields: id, user_id, item_id
}

sub out_table {
    shift->{out_table} || 'ranking' ; # fields: item_id, iuf
}

sub out_table_online { shift->out_table . '_online' }

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %$_current_table (
   item_id int not null primary key,
   count int,
   key using btree (count)
) engine = memory
},
        'cleanup' => q{truncate table %&out_table},

        'process' => q{
insert into %&out_table (item_id, count)
select item_id, count(*) count from %&in_table group by item_id
  having count >= ?
  order by count desc
  limit ?
},
    };
}

##

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

sub process {
    my $self = shift;

    my $threshold = $self->{threshold} || 3;
    my $limit = $self->{limit} || 500;

    $self->cleanup;
    $self->sql('process')->execute($threshold, $limit) or db_error;
}


1;
