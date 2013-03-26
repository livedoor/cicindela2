package Cicindela::Recommender::Cascaded;

# $Id: Cascaded.pm 9 2008-12-23 20:53:55Z tsukue $

# いくつかの set & op を組み合わせて多重引きする用
#
# 例えば youbride で男性ユーザidからおすすめの女性ユーザidを user to item でひいて，
# さらにその女性ユーザidと似ている女性ユーザidも user to user でひいてきて候補に加える，
# といった場合に使う。

# 例:
#        recommender => [ 'Cascaded', {
#            limit => 10,
#            settings => [
#                { set_name => 'set1', op => 'for_user'  },
#                { set_name => 'set2', op => 'similar_users', preserve_prev_ids => 1, exit_immediate => 1 },
#            ],
#        }],
#
#  preserve_prev_ids => 前のレベルで抽出されたidをそのまま次の段の候補に加える
#  exit_immediate => その段階で limit だけの候補がそろっていたら，次の段階には進まない


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


# op は気にしない。(=これひとつで for_user と for_item 両方は処理できない。とにかく，なんらかの id をひろっては次の Recommender につっこんでいくだけ)
sub recommend_for_item {
    my ($self, $item_id, $opts) = @_;

    return $self->_combine_results($item_id, $opts);
}

sub recommend_for_user {
    my ($self, $user_id, $opts) = @_;

    return $self->_combine_results($user_id, $opts);
}

sub similar_users {
    my ($self, $user_id, $opts) = @_;

    return $self->_combine_results($user_id, $opts);
}



sub _combine_results {
    my ($self, $id, $opts) = @_;

    my $limit = $opts->{limit} || 10;
    my $n_settings = scalar @{$self->{settings}};

    $opts = {
        %$opts,
        limit => $limit,
    };

    my @ids = ($id);
    for my $r (@{$self->{settings}}) {
        if (my $recommender = $r->{instance}) {
            # 前のidを優先的にキープで，かつ，指定個数以上idが溜まってる場合は，いちいち引く必要もない。
            unless ($r->{preserve_prev_ids} and scalar @ids >= $limit) {
                my @next_level_ids = ();
                for my $id (@ids) {
                    my $sub_list = (
                        (($r->{op} eq 'for_item') and $recommender->recommend_for_item($id, $opts))
                            or (($r->{op} eq 'for_user') and $recommender->recommend_for_user($id, $opts))
                                or (($r->{op} eq 'similar_users') and $recommender->similar_users($id, $opts)));
                    push @next_level_ids, @$sub_list  if ($sub_list and scalar @$sub_list);
                }

                @ids = () unless ($r->{preserve_prev_ids});
                push @ids, map $_->{id}, sort { $b->{score} <=> $a->{score} } @next_level_ids;
                splice @ids, $limit;
            }

            last if ($r->{exit_immediate} and scalar @ids >= $limit);
        }
    }

    # スコアはダミー
    return [ map +{ id => $_, score => 1 }, @ids ];
}


1;
