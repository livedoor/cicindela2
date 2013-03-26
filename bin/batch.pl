#!/usr/bin/perl

use strict;
use lib "/home/cicindela/lib";
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);
use Cicindela::FilterChain;
use Cicindela::LastProcessed;
#use Cicindela::TableLock;

use Getopt::Long;
my %opts;
GetOptions(\%opts, "track=s");

my $LOGGER = init_logger(config->log_conf, 1);
my $TRACK = $opts{track} || '';
$LOGGER->debug("staring batch process".($TRACK ? " track $TRACK":''));

my @pids;
my %settings = config->settings;
while (my ($set_name, $params) = each (%settings)) {
    next unless ($params->{datasource} and $params->{refresh_interval});
    next if ($TRACK ne $params->{calculation_track});

#    my $lock = new Cicindela::TableLock(
#        set_name => $set_name,
#        datasource => $params->{datasource},
#        table_name => 'flush_buffer_lock',
#    );
#    $lock->lock_on('block');
#    $LOGGER->info("acquired lockfor $set_name");

    my $timer = new Cicindela::LastProcessed(
        set_name => $set_name,
        datasource => $params->{datasource},
    );

    my ($last_starttime, $current_starttime) = $timer->check_interval($params->{refresh_interval});
    next unless ($last_starttime and $current_starttime);

    $LOGGER->info("starting $set_name, (last processed on $last_starttime)");

    Cicindela::FilterChain->new($set_name)->process;

#    $lock->lock_off;

    $LOGGER->info("$set_name done");
}

$LOGGER->debug("batch process".($TRACK ? " track $TRACK":'')." finished.");
exit;

