package Cicindela::Filters::CopyPicks::TagId2UserId;

# $Id: TagId2UserId.pm 8 2008-12-23 20:52:26Z tsukue $
#
# tag_id を user_id にみたてて picks へロードする。
# "users who chose this also chose these" -> "tags associated with this are also associated with these"
#
# CopyPicks のかわりに使う。

use strict;
use base qw(Cicindela::Filters::CopyPicks);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table_picks { shift->{in_table_picks} || 'picks' }
sub in_table_tags { shift->{in_table_tags} || 'tagged_relations' }

sub lock_tables {
    my $self = shift;

    return [
        [ $self->in_table_picks . ' as org', 'read' ],
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
  select org.item_id, tags.tag_id, org.timestamp
    from %&in_table_picks org, %&in_table_tags tags
    where org.timestamp > date_sub(now(), interval %$interval)
      and tags.user_id = org.user_id and tags.item_id = org.item_id
},

        # org.timestamp じゃなくて tags.timestamp の order by でいいなら items を join する必要はない
        # -> TagId2UserId::Simpleクラスで実装

#        'process' => q{
#insert ignore into %&out_table (item_id, user_id, timestamp)
#  select tags..item_id, tags.tag_id, tags.timestamp
#    from %&in_table_tags tags
#    where where tags.timestamp > date_sub(now(), interval %$interval)
#},

    };
}


1;
