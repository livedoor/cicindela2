package Cicindela::Filters;

# $Id: Filters.pm 10 2008-12-23 20:54:39Z tsukue $

use strict;
use base qw(Cicindela::DBI);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);
use Cicindela::TableLock;

our $LOGGER = init_logger(config->log_conf, 1);

sub short_name {
    my $self = shift;
    my $prefix = config->filters_namespace . "::";
    my ($name) = (ref($self) =~ /^$prefix(.*)$/);
    return $name;
}

sub lock_on {
    my $self = shift;

    if (my $lock_tables = $self->lock_tables) {
        $self->{lock} = new Cicindela::TableLock(
            dbh => $self->master_dbh,
            tables => $lock_tables,
        );
        $self->{lock}->lock_on;
    }
}

sub lock_off {
    my $self = shift;

    if ($self->{lock}) {
        $self->{lock}->lock_off;
    }
}

sub create_tables {
    my $self = shift;

    if (my $sth = $self->sql('create_table')) {
        $sth->execute or db_error;
    }
}

sub cleanup {
    my $self = shift;

    if (my $sth = $self->sql('cleanup')) {
        $sth->execute or db_error;
    }
}

# abstract methods

sub process { }

sub online_swaps { }

sub lock_tables { };

1;
