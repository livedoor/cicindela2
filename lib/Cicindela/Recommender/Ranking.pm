package Cicindela::Recommender::Ranking;

# $Id: Ranking.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'ranking_online' }
sub in_table_user { shift->{in_table_user} || 'picks' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'recommend_for_item' => q{
select item_id, count from %&in_table order by count desc limit ?
},

        'recommend_for_user' => q{
select result.item_id, result.score
  from
  %&in_table result
  %&_omit_uninterested
  order by result.count desc
  limit ?
},

    };
}

sub recommend_for_item {
    my ($self, $item_id, $opts) = @_;

    my $limit = $opts->{limit} || $self->{limit} || 10;

    my $sth = $self->slave_sql('recommend_for_item');
    $sth->execute($limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    my $limit = $opts->{limit} || 20;

    my $sth = $self->slave_sql('recommend_for_user');
    $sth->execute($user_id, $user_id, $limit) or db_error;
    my $rtn = [  map +{ id => $_->[0], score => $_->[1] }, @{$sth->fetchall_arrayref} ];
    $sth->finish;

    return $rtn;
}

1;
