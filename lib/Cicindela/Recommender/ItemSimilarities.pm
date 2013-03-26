package Cicindela::Recommender::ItemSimilarities;

# $Id: ItemSimilarities.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'item_similarities_online' }
sub in_table_user { shift->{in_table_user} || 'picks' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'recommend_for_item' => q{
select item_id2 item_id, score from %&in_table s
  where s.item_id1 = ?
    and s.item_id2 != ?
  order by score desc limit ?
},

        'recommend_for_user' => q{
select result.item_id, result.score
  from
  (select s.item_id2 item_id, %&scoring score
    from (select * from %&in_table_user u where u.user_id = ? order by u.timestamp desc limit ?) r,
      %&in_table s
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

    my $limit = $opts->{limit} || 10;

    my $sth = $self->slave_sql('recommend_for_item');
    $sth->execute($item_id, $item_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    my $limit = $opts->{limit} || $opts->{limit} || 20;
    my $recent_limit = $opts->{recent_limit} || $self->{recent_limit} || 100;

    my $sth = $self->slave_sql('recommend_for_user');
    $sth->execute($user_id, $recent_limit, $user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub scoring {
    my $self = shift;

    return $self->{scoring} || q{avg(s.score) * log(count(*)+1)};
#    return $self->{scoring} || q{avg(s.score)};
#    return $self->{scoring} || q{sum(s.score)};
}


1;
