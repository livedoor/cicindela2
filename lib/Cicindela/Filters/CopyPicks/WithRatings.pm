package Cicindela::Filters::CopyPicks::WithRatings;

# $Id: WithRatings.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters::CopyPicks);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub in_table { shift->{in_table} || 'ratings' }
sub out_table { shift->{out_table} || 'converted_ratings' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'create_table' => q{
create table if not exists %$_current_table (
  item_id int not null,
  user_id int not null,
  rating double,
  timestamp timestamp not null default current_timestamp,

  unique key (user_id, item_id),
  key (item_id),
  key (user_id, timestamp)
) engine = innodb
},

        'process' => q{
insert into %&out_table (item_id, user_id, rating, timestamp)
  select item_id, user_id, rating, timestamp from %&in_table
},
    };
}


1;
