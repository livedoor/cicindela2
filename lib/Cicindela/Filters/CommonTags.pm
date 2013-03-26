package Cicindela::Filters::CommonTags;

# $Id: CommonTags.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub table { shift->{table} || 'item_similarities' };
sub in_table_tags { shift->{in_table_tags} || 'tagged_relations' }; # fields: item_id, user_id, tag_id

sub sqls {
    my $self = shift;

    return {
        'tags' => q{
select tag_id, count(*) count from %&in_table_tags group by tag_id
  having count between ? and ?
  limit ?
},

        'reinforce_relation' => q{
update %&table r,
    (select distinct item_id from %&in_table_tags t where tag_id = ?) t1,
    (select distinct item_id from %&in_table_tags t where tag_id = ?) t2
  set r.score = r.score * ?
  where t1.item_id = r.item_id1
    and t2.item_id = r.item_id2
},
    };
}

sub process {
    my $self = shift;

    my $factor = $self->{factor} || 1.5;

#    my $threshold1 = $self->{threshold1} || 1000;
#    my $threshold2 = $self->{threshold2} || 2000;
#    my $limit = $self->{limit} || 100;

    my $threshold1 = $self->{threshold1} || 10;
    my $threshold2 = $self->{threshold2} || 500;
    my $limit = $self->{limit} || 20000;

    my $sth = $self->sql('tags');
    $sth->execute($threshold1, $threshold2, $limit) or db_error;
    while (my ($tag_id) = $sth->fetchrow_array) {
        $self->sql('reinforce_relation')->execute($tag_id, $tag_id, $factor) or db_error;
    }
}

1;
