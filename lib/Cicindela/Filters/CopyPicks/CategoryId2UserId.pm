package Cicindela::Filters::CopyPicks::CategoryId2UserId;

# $Id: CategoryId2UserId.pm 8 2008-12-23 20:52:26Z tsukue $
#
# category_id を user_id にみたてて picks へロードする。
#
# CopyPicks::TagId2UserId::Simple とほぼ同じ

use strict;
use base qw(Cicindela::Filters::CopyPicks);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table_categories { shift->{in_table_categories} || 'categories' }

sub lock_tables {
    my $self = shift;

    return [
        [ $self->in_table_categories . ' as categories', 'read' ],
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
  select item_id, category_id, timestamp from %&in_table_categories categories
    where categories.timestamp > date_sub(now(), interval %$interval)
},
    };
}


1;
