package Cicindela::Filters::ItemSimilarities::Express;

# $Id: Express.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters::ItemSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub out_table { shift->{out_table} || 'item_similarities_ex' }
sub in_table_org_picks { shift->{in_table_org_picks} || 'picks' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'for_each_item_id' => q{
select item_id, count(*) count, max(timestamp) timestamp from %&in_table_org_picks
  where timestamp < now() and timestamp > date_sub(now(), interval %s)
  group by item_id
  having count >= ?
-- order by item_id desc
  order by timestamp desc
  limit ?
},

    };
}

##

sub process {
    my $self = shift;

    my $recent_interval = $self->{recent_interval} || '1 hour';
    my $recent_limit = $self->{recent_limit} || '1000';

    my $threshold = $self->{threshold} || 3;
    my $limit = $self->{limit} || 30;

    my $use_counts = defined($self->{use_counts}) ? $self->{use_counts} : 1;
    $self->{_count_commentout} = $use_counts ? '' : '--';

    my $use_iuf = defined($self->{use_iuf}) ? $self->{use_iuf} : 1;
    $self->{_iuf_commentout} = $use_iuf ? '' : '--';

    my $log_base = $self->{log_base} || 2;
    my $log = log($log_base);

    $self->cleanup;

    my $sth = $self->sql('for_each_item_id', $recent_interval);
    $sth->execute($threshold, $recent_limit) or db_error;
    while (my ($item_id) = $sth->fetchrow_array) {
        $self->sql('insert_item_similarities')->execute(
            $item_id, $log, $item_id, $item_id, $threshold, $limit
        ) or db_error;
    }
    $sth->finish;
}

sub cleanup {
    my $self = shift;

    $self->sql('cleanup')->execute or db_error;
}

1;
