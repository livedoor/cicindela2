package Cicindela::Recommender::UserSimilarities;

# $Id: UserSimilarities.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'user_similarities_online' }
sub in_table_user { shift->{in_table_user} || 'picks' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'similar_users' => q{
select user_id2 user_id, score from %&in_table
  where user_id1 = ?
    and user_id2 != ?
  order by score desc limit ?
},

        'recommend_for_user' => q{
select result.item_id, result.score
  from
  (select u.item_id item_id, %&scoring score
    from (select user_id2, score from %&in_table where user_id1 = ?) s,
      %&in_table_user u
      where u.user_id = s.user_id2
      group by u.item_id
      order by score desc
      limit ?
  ) result
  %&_omit_uninterested
  order by result.score desc
  limit ?
},
    };
}

sub similar_users {
    my ($self, $user_id, $opts) = @_;

    my $limit = $opts->{limit} || $self->{limit} || 10;

    my $sth = $self->slave_sql('similar_users');
    $sth->execute($user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    my $limit = $opts->{limit} || 20;
    my $sub_limit = $opts->{sub_limit} || 2000;

    my $sth = $self->slave_sql('recommend_for_user');
    $sth->execute($user_id, $sub_limit, $user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub scoring {
    my $self = shift;

    return $self->{scoring} || q{avg(s.score) * log(count(*)+1)};
#    return $self->{scoring} || q{sum(s.score)};
#    return $self->{scoring} || q{avg(s.score)};
}

1;
