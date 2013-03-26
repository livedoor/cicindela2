package Cicindela::Filters::RatingsConverter;

# $Id: RatingsConverter.pm 8 2008-12-23 20:52:26Z tsukue $
#
# extracted_ratings テーブルの rating を補正する系の親クラス(abstract class)

use strict;
use base qw(Cicindela::Filters);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub table { shift->{table} || 'converted_ratings' };

sub sqls {
    my $self = shift;
    my $OUT_TABLE = $self->table;

    return {};
}

sub process {
    my $self = shift;
    my @args = $self->set_args;

    $self->sql('process')->execute(@args) or db_error;
}

sub set_args { }

sub cleanup { } ## 基本的にここでは create_table や truncate table 処理はしない。

1;
