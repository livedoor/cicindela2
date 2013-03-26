package Cicindela::Filters::CropPicks;

# $Id: CropPicks.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub table {  shift->{table} || 'extracted_picks' }

sub sqls {
    my $self = shift;

    my $TABLE = $self->table;

    return {
        'crop_picks' => qq{
delete b from
  (select count(*) cnt, item_id from $TABLE group by item_id having cnt < ?) a,
  $TABLE b
  where a.item_id = b.item_id
},
    };
}

sub process {
    my $self = shift;

    my $threshold = $self->{threshold} || 3;

    $self->sql('crop_picks')->execute($threshold) or db_error;
}

1;
