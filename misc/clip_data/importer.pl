#!/usr/bin/perl

use strict;
use Text::CSV_XS;
use Getopt::Long;
use Encode;

$| = 1;

my %opts;

GetOptions(\%opts, 'help', 'work_dir=s');

if ($opts{help} or !$opts{work_dir}) {
    print <<"USAGE";

reads ldclip dataset file from STDIN, writes intermediate files into [work_dir] and then prints loader sql (load data infile... statements) into STDOUT.

usage:
  perl importer.pl --work_dir=(working directory; should be accessible by mysql user)

example:
  gunzip -c ldclip_demo_dataset.csv.gz | perl importer.pl --work_dir=`pwd` | /usr/local/mysql/bin/mysql -uroot cicindela_clip_db

USAGE
    exit;
}

my $csv = Text::CSV_XS->new({ binary => 1 });
open PAGES_OUT, ">$opts{work_dir}/pages.txt" or die "can not write to file '$opts{work_dir}/pages.txt'";
open CLIPS_OUT, ">$opts{work_dir}/clips.txt" or die "can not write to file '$opts{work_dir}/clips.txt'";
open TAGS_OUT, ">$opts{work_dir}/tags.txt" or die "can not write to file '$opts{work_dir}/tags.txt'";

warn "parsing data into pages.txt, clips.txt and tags.txt...";
my $page_hash; my $last_page_id;
my $tag_hash; my $last_tag_id;
while (<>) {
    if ($csv->parse($_)) {
        my ($user_id, $url, $timestamp, $tags) = $csv->fields;

        my $page_id = $page_hash->{$url};
        unless ($page_id) {
            $page_id = ($page_hash->{$url} = ++$last_page_id);
            print PAGES_OUT join("\t", $page_id, $url)."\n";
        }

        print CLIPS_OUT join("\t", $user_id, $page_id, $timestamp)."\n";

        if ($tags) {
            for my $tag (split(/\s+/, Encode::decode('utf8', $tags))) {
                my $tag_id = ($tag_hash->{$tag} or $tag_hash->{$tag} = ++$last_tag_id);
                print TAGS_OUT join("\t", $tag_id, $user_id, $page_id, $timestamp)."\n";
            }
        }
   }
}
close PAGES_OUT;
close CLIPS_OUT;
close TAGS_OUT;
warn "done.";


warn "loading data into mysql...";
my @sqls = (
    q{truncate table picks},
    q{
load data infile '}.$opts{work_dir}. q{/clips.txt' ignore
  into table picks
  fields terminated by '\t'
  (user_id, item_id, @var1)
  set timestamp = str_to_date(@var1, "%Y-%m-%d %H:%i:%s")
},
    q{truncate table tagged_relations},
    q{
load data infile '}.$opts{work_dir}. q{/tags.txt' ignore
  into table tagged_relations
  fields terminated by '\t'
  (tag_id, user_id, item_id, @var1)
  set timestamp = str_to_date(@var1, "%Y-%m-%d %H:%i:%s")
}
);
print "$_;\n" for (@sqls);

warn "done.";


