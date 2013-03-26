package Cicindela::LastProcessed;

use strict;
use base qw(Cicindela::DBI);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);
use Cicindela::TableLock;

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        'elapsed_since_last_starttime' => q{
select now() - last_processed from last_processed where set_name = ?
},
        'get_starttimes' => q{
select last_processed, now() from last_processed where set_name = ?
},
        'set_starttime' => q{
replace into last_processed (set_name, last_processed) values (?, ?)
},
    };
}

sub elapsed_since_last_starttime {
    my $self = shift;
    my ($elapsed) = $self->select_singlerow_array(
        $self->sql('elapsed_since_last_starttime'),
        $self->{set_name},
    );
    return $elapsed;
}

sub set_starttime {
    my $self = shift;
    my ($last_starttime, $current_starttime) = $self->select_singlerow_array(
        $self->sql('get_starttimes'),
        $self->{set_name},
    );
    $self->sql('set_starttime')->execute($self->{set_name}, $current_starttime) or db_error;

    return ($last_starttime, $current_starttime);
}


# 前回実行時刻から与えられた秒数以上経っていれば、現在時刻をセットし直し、(前回のスタート時刻, 今回のスタート時刻) を返す。
# lock付き
sub check_interval {
    my ($self, $interval) = @_;

    return undef if ($interval < 0);

    my $lock = new Cicindela::TableLock(
        dbh => $self->master_dbh,
        tables => [
            ['last_processed', 'write']
        ],
    );
    $lock->lock_on;
    my $elapsed = $self->elapsed_since_last_starttime;

#    $LOGGER->debug("elapsed: $elapsed");

    if (defined($elapsed) and $elapsed < $interval) {
        $lock->lock_off;
        return undef;
    }

    my ($last_starttime, $current_starttime) = $self->set_starttime;
    $lock->lock_off;
    return ($last_starttime, $current_starttime);
}

1;
