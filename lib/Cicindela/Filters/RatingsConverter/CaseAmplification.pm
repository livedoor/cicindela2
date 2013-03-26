package Cicindela::Filters::RatingsConverter::CaseAmplification;

# $Id: CaseAmplification.pm 8 2008-12-23 20:52:26Z tsukue $

use strict;
use base qw(Cicindela::Filters::RatingsConverter);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        %{$self->SUPER::sqls},

        'process', q{
update %&table set rating = sign(rating) * pow(rating * ? * sign(rating), ?)
},
    };
}

sub set_args {
    my $self = shift;

    my $factor = $self->{factor} || 1;
    my $pow = $self->{pow} || 2;
    return ($factor, $pow);
}

1;
