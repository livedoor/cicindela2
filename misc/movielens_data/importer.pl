#!/usr/bin/perl

use strict;
use Getopt::Long;

$| = 1;

my %opts;

GetOptions(\%opts, 'help', 'work_dir=s');

if ($opts{help} or !$opts{work_dir}) {
    print <<"USAGE";

reads movielens dataset file from [work_dir]/ratings.dat and prints loader sql (load data infile... statements) into STDOUT.
 (designed for reading 1,000,000 data set from http://www.grouplens.org/node/73)

usage:
  perl importer.pl --work_dir=(working directory; should contain ratings.dat and be accessible by mysql user)

example:
  perl importer.pl --work_dir=`pwd` | /usr/local/mysql/bin/mysql -uroot cicindela_movielens_db

USAGE
    exit;
}

my @sqls = (
    q{truncate table ratings},
    q{
load data infile '}.$opts{work_dir}.q{/ratings.dat'
  into table ratings
  fields terminated by '::'
  (user_id, item_id, rating, @var1)
  set timestamp = from_unixtime(@var1)
},
);
print "$_;\n" for (@sqls);


