package Cicindela::TableLock;

use strict;
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub new {
    my $class = shift;

    my $self = bless {
        @_,
    }, $class;
    return $self;
}

sub dbh {
    my $self = shift;
    die 'dbh not specified' unless $self->{dbh};
    return $self->{dbh};
}

sub tables {
    my $self = shift;
    die 'lock table names not specified' unless $self->{tables};
    return $self->{tables};
}

sub lock_on {
    my ($self, $blocking_mode) = @_;

    $self->{original_autocommit_mode} = $self->dbh->{AutoCommit};
    $self->dbh->{AutoCommit} = 0;
    $LOGGER->debug("original autocommit mode:".$self->{original_autocommit_mode}.", temporarily changed to 0");

    while (1) {
        eval {
            my $tables_clause = join(',', map $_->[0].' '.$_->[1], @{$self->tables});
            $LOGGER->debug("locking tables: $tables_clause");
            $self->dbh->do("lock tables $tables_clause");
        };
        if ($@) {
            return 0 if $blocking_mode eq 'non_block';
            $LOGGER->info('table lock failed (may be timed out). retrying.');
        } else {
            return 1;
        }
    }
}

sub lock_off {
    my $self = shift;

    $self->dbh->do('unlock tables') or db_error;

    if ($self->{original_autocommit_mode}) {
        $self->dbh->do('commit') or db_error;
    }
    $LOGGER->debug("unlocked all tables; resuming autocommit mode:".$self->{original_autocommit_mode});
    $self->dbh->{AutoCommit} = $self->{original_autocommit_mode};
}


1;

