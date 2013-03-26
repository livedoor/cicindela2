package Cicindela::Filters::RatingsConverter::Log;

# $Id: Log.pm 8 2008-12-23 20:52:26Z tsukue $
#
# log

use strict;
use base qw(Cicindela::Filters::RatingsConverter);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'process' => q{
update %&table set rating = log(rating) / log(?)
},
    };
}

sub set_args {
    my $self = shift;

    my $log_base = $self->{log_base} || 2;
    return ($log_base);
}


1;
