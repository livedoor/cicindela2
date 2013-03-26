package Cicindela::Filters::RatingsConverter::InverseUserFrequency;

# $Id: InverseUserFrequency.pm 8 2008-12-23 20:52:26Z tsukue $
#
# ratingsを上書きするタイプ
# だが、ItemSimiarities で特にレーティングが1/0のみの場合、たぶんここでやっても↓の計算
#   avg(r1.rating*r2.rating) / sqrt(avg(r1.rating*r1.rating)*avg(r2.rating*r2.rating))
# のとこで打ち消されちゃう予感。
# ItemSimilarities.pm のほうに iuf 調整つけたので、item similarities系ではこれを適用する意味なし。
# slope one diffs 系の場合はこっちを使った方がいいのかな ??

use strict;
use base qw(Cicindela::Filters::RatingsConverter);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'total_users' => q{
select count(distinct user_id) from %&table
},

        'process' => q{
update %&table r,
    (select item_id, count(*) cnt from %&table group by item_id) counts
  set r.rating = r.rating * log(? / counts.cnt) / ?
  where r.item_id = counts.item_id
},
    };
}

sub process {
    my $self = shift;

    my $log_base = $self->{log_base} || 2;
    my $log = log($log_base);

    my ($total_users) = $self->select_singlerow_array($self->sql('total_users'));
    $self->sql('process')->execute($total_users, $log) or db_error;
}

1;
