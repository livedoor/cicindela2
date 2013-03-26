package Cicindela::Utils;

#
# $Id: Utils.pm 10 2008-12-23 20:54:39Z tsukue $
#
# クラスを分けるまでもない雑多なファンクション集
# Config::MixIn には依存しない
#

use strict;
use base qw(Exporter);
use DBI;
use Data::Dumper;
use Time::Piece;
use Log::Log4perl qw(:easy);
use Time::HiRes qw(gettimeofday tv_interval);
# use Fcntl ':flock';

our @FILTER_FUNCTIONS = qw(nl2br strftime_filter);
our @VALIDATE_FUNCTIONS = qw();
our @DATETIME_FUNCTIONS = qw(now curdate);
our @STANDARD_FUNCTIONS = qw(
                             init_db db_error
                             init_logger
                             member_of unique smaller larger select_random safe_division
                        );
our @EXPORT_OK = (
    @FILTER_FUNCTIONS,
    @VALIDATE_FUNCTIONS,
    @DATETIME_FUNCTIONS,
    @STANDARD_FUNCTIONS,
    );
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    filter => \@FILTER_FUNCTIONS,
    validator => \@VALIDATE_FUNCTIONS,
    datetime => \@DATETIME_FUNCTIONS,
    standard => \@STANDARD_FUNCTIONS,
    );

#
# Sledge filter functions
#

sub nl2br {
    my $str = shift;
    $str =~ s/(\r\n?|\n)/<br>\n/sg;
    return $str;
}

# allowed datetime formats are below.
# YYYY-mm-dd HH:MM:SS, YYYYmmddHHMMSS and YYYY-mm-dd
# for TT use only.
sub strftime_filter {
    my($context, $format) = @_;
    return sub {
        my $text = shift;
        require Time::Piece;
        return '' unless $text;
        my $t = 
            eval { Time::Piece->strptime($text, '%Y-%m-%d %H:%M:%S') } ||
                eval { Time::Piece->strptime($text, '%Y%m%d%H%M%S') } ||
                    eval { Time::Piece->strptime($text, '%Y-%m-%d') };
        return '' unless $t;
        return $t->strftime($format);
    };
}

#
# DateTime functions
#

sub now { Time::Piece->new->strftime('%Y-%m-%d %H:%M:%S'); }
sub curdate { Time::Piece->new->strftime('%Y-%m-%d'); }


#
# trivial functions
#

sub member_of {
    my ($target, @list) = @_;
    foreach (@list) { return 1 if ($_ eq $target);}
    return 0;
}

sub unique {
    return do { my %tmp; grep(!$tmp{$_}++, @_) };
}

sub smaller {
    return ($_[0] > $_[1]) ? $_[1] : $_[0];
}

sub larger {
    return ($_[0] > $_[1]) ? $_[0] : $_[1];
}

sub select_random {
    my $array = shift;

    return $array->[ int( rand( scalar @$array ))];
}

sub safe_division {
    return ($_[1] ? $_[0]/$_[1] : 0);
}


#
# ログ関連
#

Log::Log4perl::Layout::PatternLayout::add_global_cspec('E',
    sub {
        our $LAST_MESSAGE_TIME;

        my $mes = sprintf("%.3f sec from start", tv_interval($Log::Log4perl::Layout::PatternLayout::PROGRAM_START_TIME));
        if ($LAST_MESSAGE_TIME) {
            $mes .= sprintf(", %.3f sec from last msg." , tv_interval($LAST_MESSAGE_TIME));
        }
        $LAST_MESSAGE_TIME = [gettimeofday];
        return $mes;
    });

Log::Log4perl::Layout::PatternLayout::add_global_cspec('B',
    sub {
        return "$0, pid $$";
    });

sub init_logger {
    my ($path, $catch_stderr) = @_;

    if ($catch_stderr) {
        $SIG{__DIE__} = sub {
            $Log::Log4perl::caller_depth++;
            LOGDIE @_;
        };
        $SIG{__WARN__} = sub {
            local $Log::Log4perl::caller_depth =
                $Log::Log4perl::caller_depth + 1;
            WARN @_;
        };
    }

    Log::Log4perl->init_once($path);
    return Log::Log4perl->get_logger(caller);
}

#
# ロック関係
#

# sub lock_on {
# 	my ($path, $module, $mode) = @_; # non blocking mode if $mode eq 'LOCK_NB'

# 	my $filename = $path . '/' . $module . '.lock';

# 	my $LOCK = &open_new_FH(">$filename") or die("can not open lock file $filename");
# 	if ($mode ne 'LOCK_NB') {
# 		flock($LOCK, LOCK_EX) or die("can not flock $filename");
# 	} else {
# 		flock($LOCK, LOCK_EX | LOCK_NB) || undef $LOCK; # LOCK_NBモードの場合は不成功時 null を返す
# 	}

# 	return $LOCK;
# }

# sub lock_off {
# 	my($LOCK) = @_;

# 	flock($LOCK, LOCK_UN);
# 	close($LOCK);
# }

# sub open_new_FH {
# 	my ($stream) = @_;
# 	local *FH;  # not my!

# 	open (FH, $stream) or return undef;
# 	return *FH;
# }

#
# DB関連
#

our $DBH;
sub init_db {
    my @datasource = @_;

    my $key = join(',',@datasource);
    if (!$DBH->{$key}) {
        $DBH->{$key} = DBI->connect(@datasource, { RaiseError => 1, AutoCommit => 1 }) or &db_error;
        $DBH->{$key}->trace(2);
    }

    return $DBH->{$key};
}

sub db_error {
    my $logger = Log::Log4perl->get_logger();
    my $message = $DBI::errstr;

    $logger->logcroak($message);
}



1;
