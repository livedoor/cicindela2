package Cicindela::Filters::UserSimilarities::CopyFromOtherDB;

# $Id: CopyFromOtherDB.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters::UserSimilarities);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub src_table { shift->{src_table} }
sub src_columns { shift->{src_columns} || join(',', qw(user_id1 user_id2 score)) }
sub out_table { shift->{out_table} || 'user_similarities' }
sub out_table_online { shift->out_table . '_online' }

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'copy' => q{
insert into %&out_table (user_id1, user_id2, score)
  select %&src_columns from %&src_table
},
    };
}

sub process {
    my $self = shift;

    $self->cleanup;

    $self->sql('copy')->execute or db_error;
}


1;
