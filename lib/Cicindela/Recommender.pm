package Cicindela::Recommender;

use strict;
use base qw(Cicindela::DBI);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);

sub sqls {
    my $self = shift;

    return {
        item_id_char2int => q{
select id from item_id_char2int where char_id = ?
    },
        item_id_int2char => q{
select char_id from item_id_char2int where id = ?
    },
        user_id_char2int => q{
select id from user_id_char2int where char_id = ?
    },
        user_id_int2char => q{
select char_id from user_id_char2int where id = ?
    },
    };
}

sub _item_id_char2int {
    my ($self, $char_id) = @_;
    my ($id) = $self->select_singlerow_array($self->sql('item_id_char2int'), $char_id);
    return $id;
}
sub _item_id_int2char {
    my ($self, $id) = @_;
    my ($char_id) = $self->select_singlerow_array($self->sql('item_id_int2char'), $id);
    return $char_id;
}
sub _user_id_char2int {
    my ($self, $char_id) = @_;
    my ($id) = $self->select_singlerow_array($self->sql('user_id_char2int'), $char_id);
    return $id;
}
sub _user_id_int2char {
    my ($self, $id) = @_;
    my ($char_id) = $self->select_singlerow_array($self->sql('user_id_int2char'), $id);
    return $char_id;
}

# Handlers/Recommend から呼ばれる部分。
# ほとんど recommend_for_item とか recommend_for_user とかを呼ぶだけ
# 最終出力に必要な，共通のフィルタリングや整形をここでする。
# ・余計なフィールドをおとす
# ・char_id の解決をする
# ・scoreが低すぎる(0以下)の候補を外す ← recommend_for_item などの中で個々のメソッドがやるべきか?
sub output_recommend_for_item {
    my $self = shift;
    my $item_id = shift;

    my $recommendations = $self->recommend_for_item(
        ($self->{use_item_char_id} ? $self->_item_id_char2int($item_id) : $item_id),
        @_
    );

    return [
        map { $self->{use_item_char_id} ? $self->_item_id_int2char($_->{id}) : $_->{id} }
            grep { !defined($self->{score_threshold}) or $_->{score} > $self->{score_threshold} }
                @$recommendations
            ];
}

sub output_recommend_for_user {
    my $self = shift;
    my $user_id = shift;

    my $recommendations = $self->recommend_for_user(
        ($self->{use_user_char_id} ? $self->_user_id_char2int($user_id) : $user_id),
        @_
    );

    return [
        map { $self->{use_item_char_id} ? $self->_item_id_int2char($_->{id}) : $_->{id} }
            grep { !defined($self->{score_threshold}) or $_->{score} > $self->{score_threshold} }
                @$recommendations
            ];
}

sub output_similar_users {
    my $self = shift;
    my $user_id = shift;

    my $recommendations = $self->similar_users(
        ($self->{use_user_char_id} ? $self->_user_id_char2int($user_id) : $user_id),
        @_
    );


    return [
        map { $self->{use_user_char_id} ? $self->_user_id_int2char($_->{id}) : $_->{id} }
            grep { !defined($self->{score_threshold}) or $_->{score} > $self->{score_threshold} }
                @$recommendations
            ];
}

# recommend_for_user で補助的に使われる clause 組み立て用
# ユーザのピックアップ済のエントリを除外する
# 結果出力に result という名前がついていて，プレースホルダー2個にそれぞれ user_id, user_id がバインドされる前提。
sub _omit_uninterested {
    my ($self, $user_id, $opts) = @_;

    my $table = $self->in_table_user;
    if ($self->{use_uninterested}) {
        return qq{
  left outer join $table uninterested1
    on result.item_id = uninterested1.item_id and uninterested1.user_id = ?
  left outer join uninterested uninterested2
    on result.item_id = uninterested2.item_id and uninterested2.user_id = ?
  where uninterested1.item_id is null and uninterested2.item_id is null
};
    } else {
        return qq{
  left outer join $table uninterested1
    on result.item_id = uninterested1.item_id and uninterested1.user_id = ?
  where uninterested1.item_id is null
-- ? ## just for adjusting number of user_id place holders
};
    }
}

# abstract methods

sub recommend_for_item { }

sub recommend_for_user { }

sub similar_users { }


# class methods

sub get_instance {
    my ($class, $recommender_class, $init_args) = @_;
    
    $recommender_class = join('::', __PACKAGE__, $recommender_class);
    eval ("use $recommender_class");
    if ($@) { warn $@; return undef; }

    return $recommender_class->new(%$init_args);
}

sub get_instance_for_set {
    my ($class, $set_name) = @_;

    my $setting = config->settings->{$set_name};
    my $init_args;

    my $recommender_class = $setting->{recommender};
    unless ($recommender_class) {
	$LOGGER->warn("recommender not found for set '$set_name'");
	return undef;
    }

    if (ref($recommender_class) eq 'ARRAY') {
        ($recommender_class, $init_args) = @$recommender_class;
    }

    return $class->get_instance(
        $recommender_class,
        {
            set_name => $set_name,

            datasource => $setting->{datasource},
            slave_datasource => $setting->{slave_datasource},
            use_item_char_id => $setting->{use_item_char_id},
            use_user_char_id => $setting->{use_user_char_id},

            %{$init_args || {}},
        }
    );
}

1;
