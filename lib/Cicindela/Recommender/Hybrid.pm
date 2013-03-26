package Cicindela::Recommender::Hybrid;

# $Id: Hybrid.pm 9 2008-12-23 20:53:55Z tsukue $

use strict;
use base qw(Cicindela::Recommender);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    for my $s (@{$self->{settings}}) {
        $s->{instance} = Cicindela::Recommender->get_instance_for_set($s->{set_name});
    }

    return $self;
}

sub recommend_for_item {
    my ($self, $item_id, $opts) = @_;

    return $self->_combine_results('for_item', $item_id, $opts);
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    return $self->_combine_results('for_user', $user_id, $opts);
}

sub similar_users {
    my ($self, $user_id, $opts) = @_;

    return $self->_combine_results('similar_users', $user_id, $opts);
}

sub _combine_results {
    my ($self, $mode, $id, $opts) = @_;

    my $limit = $opts->{limit} || ($mode eq 'for_item' ? 10 : 20);
    my $sub_limit_factor = $opts->{sub_limit_factor} || 3;
    my $n_settings = scalar @{$self->{settings}};

    $opts = {
        %$opts,
        limit => $limit * $sub_limit_factor,
    };

    my $results;
    my $factor_sum = 0;
    for my $r (@{$self->{settings}}) {
        if (my $recommender = $r->{instance}) {
            my $list = (
                (($mode eq 'for_item') and $recommender->recommend_for_item($id, $opts))
             or (($mode eq 'for_user') and $recommender->recommend_for_user($id, $opts))
             or (($mode eq 'similar_users') and $recommender->similar_users($id, $opts)));
            if ($list and scalar @$list) {
                my $max_score = $list->[0]->{score};
                my $min_score = $list->[-1]->{score};

                for my $entry (@$list) {
#                    $entry->{score} *= $r->{factor};
                    $entry->{score} = $r->{factor}
                        * (($max_score != $min_score) ? ($entry->{score} - $min_score) / ($max_score - $min_score) : 0.5);

                    if ($results->{$entry->{id}}) {
                        $results->{$entry->{id}}->{score} += $entry->{score};
                    } else {
                        $results->{$entry->{id}} = $entry;
                    }
                }
                $factor_sum += $r->{factor};
            }
        }
        last if ($factor_sum >= 1);
    }

    my @rtn = sort { $b->{score} <=> $a->{score} } values (%$results);
    splice @rtn, $limit;

    return \@rtn;
}


1;
