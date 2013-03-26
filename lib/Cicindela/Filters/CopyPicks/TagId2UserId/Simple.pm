package Cicindela::Filters::CopyPicks::TagId2UserId::Simple;

# $Id: Simple.pm 8 2008-12-23 20:52:26Z tsukue $
#
# TagId2UserIdと同じだが、アイテムの新しい順ではなくて、タグの新しい順にピックアップする
# (古いアイテムへのタグが更新されると、そのアイテムが浮上してしまう。アイテムの新鮮さを
#  重視するclipなんかではちょっと問題があるかもしれないが、SQL的には早い)

use strict;
use base qw(Cicindela::Filters::CopyPicks::TagId2UserId);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub lock_tables {
    my $self = shift;

    return [
        [ $self->in_table_tags . ' as tags', 'read' ],
        [ $self->out_table, 'write' ],
    ];
}

sub sqls {
    my $self = shift;
    $self->{interval} ||= '6 month';

    return {
        %{$self->SUPER::sqls},

        'process' => q{
insert ignore into %&out_table (item_id, user_id, timestamp)
  select tags.item_id, tags.tag_id, tags.timestamp
    from %&in_table_tags tags
    where tags.timestamp > date_sub(now(), interval %$interval)
},

    };
}


1;
