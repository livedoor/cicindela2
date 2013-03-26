package Cicindela::Recommender::SlopeOneDiffs::LimitCategory;

# $Id: LimitCategory.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::SlopeOneDiffs);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table_categories {
    return shift->{in_table_categories} || 'categories';
}

sub sqls {
    my $self = shift;
    return {
        %{$self->SUPER::sqls},

        'recommend_for_item_with_category' => q{
select item_id2 item_id, diff
  from %&in_table s, %&in_table_categories c
  where s.item_id1 = ?
    and s.item_id2 != ?
    and c.item_id = s.item_id2 and c.category_id = ?
  order by diff desc limit ?
},

        'recommend_for_user_with_category' => q{
select result.item_id, result.score
  from
  (select item_id2 item_id,
      sum((r.rating + s.diff) * s.count)/sum(s.count) score
--      avg(r.rating + s.diff) score
    from (select * from %&in_table_user where user_id = ? order by timestamp desc limit ?) r,
      %&in_table s, %&in_table_categories c
    where s.item_id1 = r.item_id
      and c.item_id = s.item_id2 and c.category_id = ?
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

    return $self->SUPER::recommend_for_item($item_id, $opts) unless $opts->{category_id};

    my $limit = $opts->{limit} || 10;
    my $category_id = $opts->{category_id};

    my $sth = $self->slave_sql('recommend_for_item_with_category');
    $sth->execute($item_id, $item_id, $category_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    return $self->SUPER::recommend_for_user($user_id, $opts) unless $opts->{category_id};

    my $limit = $opts->{limit} || $opts->{limit} || 20;
    my $recent_limit = $opts->{recent_limit} || $self->{recent_limit} || 100;
    my $category_id = $opts->{category_id};

    my $sth = $self->slave_sql('recommend_for_user_with_category');
    $sth->execute($user_id, $recent_limit, $category_id, $user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}


1;
