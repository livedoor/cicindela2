#!/usr/bin/perl

# create maintenamce user by
#  SQL>grant super, replication client on *.* to 'maintenance'@'%' identified by 'password'
# and edit definitions 'db_maintenance_master' and 'db_maintenance_slave' in lib/Cicindela/Config/_*.pm
#
# based on:
#   http://dev.mysql.com/doc/refman/5.0/en/log-file-maintenance.html
#
# $Id: cleanup_mysql_binlog.pl 4 2008-12-23 20:44:30Z tsukue $

use strict;
use lib "/home/cicindela/lib";
use Cicindela::Utils qw(:all);
use Cicindela::Config::MixIn;

#
# setup necessary objs.
#

my $logger = init_logger(config->log_conf, 1);

my $offset = 2;

for my $setting (config->db_maintenance_sets) {
    cleanup($setting->{master}, $setting->{slave})
}
exit;


sub cleanup {
    my ($master_dsn, $slave_dsn) = @_;

    return unless (@$master_dsn);

    my $master_dbh = init_db(@$master_dsn);
    my $slave_dbh;
    my $last;
    if ($slave_dsn and @$slave_dsn > 0) {
        $slave_dbh = init_db(@$slave_dsn);

        ## ask slave which is the last file he has
        my $sth = $slave_dbh->prepare(q{show slave status});
        $sth->execute or db_error;
        my $r = $sth->fetchrow_hashref;
        $last = $r->{Master_Log_File};
        $sth->finish;
    } else {
        my $sth = $master_dbh->prepare(q{show master status});
        $sth->execute or db_error;
        my $r = $sth->fetchrow_hashref;
        $last = $r->{File};
        $sth->finish;
    }

    ## extract number out of filename
    my @tmp = split(/\./, $last);
    my $file	= $tmp[0];
    my $number	= $tmp[1];
    my $len	 = length($number);

    ## skip the last $offset files
    if (int($number) > $offset) {
        $number -= $offset;

        ## fill string with lots of zeros, just to make sure (the are surely better ways to do this, but it works (hopefully :))
        for (my $x = 0; $x < $len; $x++) {
            $number = "0" . $number;
        }

        ## cut out only the amount of zeros we want
        $number = substr($number, (length($number) - $len), length($number));

        ## filename we want to purge too
        my $purge	= $file . "." . $number;

        ## purge on master
        $logger->info("purging master logs to $purge");
        $master_dbh->do(qq{purge master logs to '$purge'}) or db_error;
    }

    $master_dbh->disconnect;
    $slave_dbh->disconnect if $slave_dbh;
}

