#!/usr/bin/perl

use strict;
use Getopt::Long;

$| = 1;

my %opts;

GetOptions(\%opts, 'help', 'base_sql=s', 'db_name=s', 'grant_user=s', 'grant_host=s', 'grant_pass=s');

if ($opts{help} or !$opts{db_name}) {
    print <<"USAGE";

prints initial sql for cicindela into STDOUT.

usage: 
  perl create_init_sql.pl --db_name=(database name to be created) [--grant_user=(user name to grant access to) --grant_host=(host) --grant_pass=(pass) ]

example:
  perl create_init_sql.pl --db_name=cicindela_clip_db | /usr/local/mysql/bin/mysql -uroot

USAGE
    exit;
}

my $file = $opts{base_sql} || 'cicindela.sql';
open IN, $file or die "base sql file $file not found.";
while (<IN>) {
    s/\$DB_NAME/$opts{db_name}/g;
    print $_;
}
close IN;

if ($opts{grant_user}) {
    print qq{grant all on $opts{db_name}.* to "$opts{grant_user}"@"$opts{grant_host}" identified by "$opts{grant_pass}";\n};
    print qq{flush privileges;\n};
}


