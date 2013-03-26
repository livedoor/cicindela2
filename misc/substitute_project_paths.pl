#!/usr/bin/perl

use strict;
use Getopt::Long;

my %opts;
GetOptions(\%opts, "help", "perl_path=s", "cicindela_home=s");

if ($opts{help}) {
    print <<"USAGE";

substitutes hard-coded paths in all project files.

usage:
  perl substitute_project_paths.pl --perl_path=(path to perl) --cicindela_home=(path to cicindela dir; no trailing '/') [ --dir=(root dir to examine; default "..") --ignore_ext=(file extensions to be ignored; separated by ','; default "txt,gz,t") ]

example:
  perl substitute_project_paths.pl --perl_path=/usr/local/bin/perl --cicindela_home=/user/home/cicindela --dir=.. --ignore=gz,txt,t

USAGE
    exit;
}

my $default_perl_path = '/usr/bin/perl';
my $default_cicindela_home = '/home/cicindela';
my $dir = $opts{dir} || "..";
my @ignore_ext = $opts{ignore_ext} ? split(/,/, $opts{ignore_ext}) : qw(gz txt t);

my @dirs = ($dir);
while (my $current_dir = pop(@dirs)) {
    opendir DIR, $current_dir;
    while (my $file = readdir(DIR)) {
        next if $file =~ /^[\.~#]/;
        next if grep {$file =~ /\.$_$/} @ignore_ext;

        $file = join('/', $current_dir, $file);
        if (-d $file) {
            push @dirs, $file;
        } else {
            print "$file\n";
            system (qq{sed -e 's!$default_perl_path!$opts{perl_path}!g' -i "" $file}) if ($opts{perl_path});
            system (qq{sed -e 's!$default_cicindela_home!$opts{cicindela_home}!g' -i "" $file}) if ($opts{cicindela_home});
        }
    }
}

