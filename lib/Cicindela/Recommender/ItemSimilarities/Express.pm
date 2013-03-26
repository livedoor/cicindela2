package Cicindela::Recommender::ItemSimilarities::Express;

# $Id: Express.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::ItemSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table_ex { shift->{in_table} || 'item_similarities_ex_online' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'recommend_for_item_ex' => q{
select item_id2 item_id, score from %&in_table_ex
  where item_id1 = ?
    and item_id2 != ?
  order by score desc limit ?
},

        'recommend_for_user_ex' => qq{
select result.item_id, result.score
  from
  (select s.item_id2 item_id,
--      avg(s.score) score
      sum(s.score) score
    from  (select * from %&in_table_user where user_id = ? order by timestamp desc limit ?) r,
      %&in_table_ex s
    where s.item_id1 = r.item_id
    group by s.item_id2
  ) result
  %&_omit_uninterested
  order by result.score desc
  limit ?
},

    };
}

sub recommend_for_item {
    my ($self, $item_id, $opts) = @_;

    my $rtn = $self->SUPER::recommend_for_item($item_id, $opts);
    return $rtn if $rtn;

    my $limit = $opts->{limit} || 10;

    my $sth = $self->slave_sql('recommend_for_item_ex');
    $sth->execute($item_id, $item_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub recommend_for_user {
    my ($self, $user_id) = @_;

    my $rtn = $self->SUPER::recommend_for_user($user_id, $opts);
    return $rtn if $rtn;

    my $limit = $opts->{limit} || 10;
    my $recent_limit = $opts->{recent_limit} || 100;

    my $sth = $self->slave_sql('recommend_for_user_ex');
    $sth->execute($user_id, $recent_limit, $user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

1;
