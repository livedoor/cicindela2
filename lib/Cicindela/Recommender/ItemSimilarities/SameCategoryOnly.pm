package Cicindela::Recommender::ItemSimilarities::SameCategoryOnly;

# $Id: SameCategoryOnly.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender::ItemSimilarities);
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

        'get_categories' => q{
select category_id from %&in_table_categories where item_id = ?
},
    };
}

sub recommend_for_item {
    my ($self, $item_id, $opts) = @_;

    my $sth = $self->slave_sql('get_categories');
    $sth->execute($item_id) or db_error;
    my $category_ids = join(',', map $_->[0], @{$sth->fetchall_arrayref});
    $sth->finish;
    return unless $category_ids;

    my $original_in_table = $self->in_table;
    my $in_table_categories = $self->in_table_categories;
    $self->{in_table} = qq{
(select * from $original_in_table a,
    (select distinct item_id from $in_table_categories where category_id in ($category_ids) )b
  where a.item_id1 = $item_id and a.item_id2 = b.item_id
)
};
    return $self->SUPER::recommend_for_item($item_id, $opts);
}

1;
