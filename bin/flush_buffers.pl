#!/usr/bin/perl

use strict;
use lib "/home/cicindela/lib";
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);
use Cicindela::IncomingData;
use Cicindela::TableLock;

use Getopt::Long;
my %opts;
GetOptions(\%opts, "set=s", "table=s");

my $LOGGER = init_logger(config->log_conf, 1);
$LOGGER->debug("staring flush_buffers process");

my %settings = config->settings;
while (my ($set_name, $params) = each (%settings)) {
    next unless ($params->{datasource});
    next if (defined($opts{set}) and $opts{set} ne $set_name);

    my $flusher = new Cicindela::IncomingData(
        set_name => $set_name,
        %{config->settings->{$set_name}},
    );
    $flusher->flush_buffers($opts{table});
    $LOGGER->debug("$set_name buffer flush done");

    $flusher->cleanup;
    $LOGGER->debug("$set_name cleanup done");

#    $lock->lock_off;
}

$LOGGER->debug("flush_buffers process finished");

exit;

