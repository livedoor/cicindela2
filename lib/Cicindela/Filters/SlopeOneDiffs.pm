package Cicindela::Filters::SlopeOneDiffs;

# $Id: SlopeOneDiffs.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'extracted_ratings' }
# sub in_table_iuf { shift->{in_table} || 'iuf' }
sub out_table { shift->{out_table} || 'slope_one_diffs' }
sub out_table_online { shift->out_table .'_online' }

sub sqls {
    my $self = shift;

    return {
        'create_table' => q{
create table if not exists %$_current_table (
   item_id1 int not null,
   item_id2 int not null,
   count int,
   diff double,

   key using hash (item_id1)
) engine = memory
},

        'cleanup' => q{truncate table %&out_table},

        'for_each_item_id' => q{
select distinct item_id from %&in_table
},

        'insert' => q{
insert into %&out_table (item_id1, item_id2, count, diff)
  select r1.item_id, r2.item_id, count(*) count, avg(r2.rating - r1.rating) diff
    from %&in_table r1, %&in_table r2
    where r1.item_id = ?
      and r1.user_id = r2.user_id
      and r2.item_id != ?
    group by r1.item_id, r2.item_id
    having count > ?
    order by count desc, diff desc limit ?
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

    $self->cleanup;

    my $sth = $self->sql('for_each_item_id');
    $sth->execute or db_error;
    while (my ($item_id) = $sth->fetchrow_array) {
        $self->sql('insert')->execute($item_id, $item_id, $threshold, $limit) or db_error;
    }
    $sth->finish;
}



1;
