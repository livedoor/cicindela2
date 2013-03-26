package Cicindela::IncomingData;

use strict;
use base qw(Cicindela::DBI);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);
use Cicindela::TableLock;

our $LOGGER = init_logger(config->log_conf, 1);


sub sqls {
    my $self = shift;

    return {
        # バッファを使う時用。
        # 解析が走ってても insert がロックされない & user_id や char_id が int でなくてもok
        'insert_picks_buffer' => q{
insert into picks_buffer (user_id, user_char_id, item_id, item_char_id, is_delete, timestamp) values (?, ?, ?, ?, ?, now())
},
        'insert_uninterested_buffer' => q{
insert into uninterested_buffer (user_id, user_char_id, item_id, item_char_id, is_delete, timestamp) values (?, ?, ?, ?, ?, now())
},
        'insert_ratings_buffer' => q{
insert into ratings_buffer (user_id, user_char_id, item_id, item_char_id, rating, is_delete, timestamp) values (?, ?, ?, ?, ?, ?, now())
},
        'insert_tags_buffer' => q{
insert into tagged_relations_buffer (tag_id, user_id, user_char_id, item_id, item_char_id, is_delete, timestamp) values (?, ?, ?, ?, ?, ?, now())
},
        'insert_categories_buffer' => q{
insert into categories_buffer (category_id, item_id, item_char_id, is_delete, timestamp) values (?, ?, ?, ?, now())
},

        'flush_buffer1' => q{select max(id) from %$buffer_table},
        'flush_buffer2_insert' => q{
insert ignore into %$out_table (%$fieldslist) select %$fieldslist from %$buffer_table src where id <= ? and is_delete = 0
%$update_clause
},
        'flush_buffer2_delete' => q{
delete tgt from %$out_table tgt, %$buffer_table src where %$delete_fieldslist and src.id <= ? and src.is_delete = 1
},
        'flush_buffer3' => q{delete from %$buffer_table where id <= ?},


        # int以外の型のidの変換用
        'insert_user_char_id' => q{
insert ignore into user_id_char2int (char_id) values (?)
},
        'insert_item_char_id' => q{
insert ignore into item_id_char2int (char_id) values (?)
},

        'resolve_user_ids' => q{
update %$buffer_table a, user_id_char2int b
  set a.user_id = b.id
  where a.id <= ? and a.user_char_id = b.char_id
},
        'resolve_item_ids' => q{
update %$buffer_table a, item_id_char2int b
  set a.item_id = b.id
  where a.id <= ? and a.item_char_id = b.char_id
},

        # テーブルが大きくなりすぎない用
        'cleanup_user_id_char2int' => q{delete from user_id_char2int where timestamp < date_sub(now(), interval %$discard_user_id_char2int) },
        'cleanup_item_id_char2int' => q{delete from item_id_char2int where timestamp < date_sub(now(), interval %$discard_item_id_char2int) },
        'cleanup_picks' => q{delete from picks where timestamp < date_sub(now(), interval %$discard_picks)},
        'cleanup_uninterested' => q{delete from uninterested where timestamp < date_sub(now(), interval %$discard_uninterested)},
        'cleanup_ratings' => q{delete from ratings where timestamp < date_sub(now(), interval %$discard_ratings)},

        # テーブルの存在確認用 (for backwards compatility)
        'check_table_existance' => q{show tables like ?},
        'check_buffer_columns' => q{desc %$buffer_table},
    };
}

sub insert_pick {
    my ($self, $user_id, $item_id, $is_delete) = @_;

    $is_delete = 0 unless defined($is_delete);

    my ($user_char_id, $item_char_id);
    if ($self->{use_user_char_id}) {
        $user_char_id = $user_id; undef($user_id);
        $self->sql('insert_user_char_id')->execute($user_char_id) or db_error;
    }
    if ($self->{use_item_char_id}) {
        $item_char_id = $item_id; undef($item_id);
        $self->sql('insert_item_char_id')->execute($item_char_id) or db_error;
    }

    $self->sql('insert_picks_buffer')->execute($user_id, $user_char_id, $item_id, $item_char_id, $is_delete)
        or db_error;
}

sub delete_pick {
    my ($self, $user_id, $item_id) = @_;
    $self->insert_pick($user_id, $item_id, 1);
}

sub insert_uninterested {
    my ($self, $user_id, $item_id, $is_delete) = @_;

    $is_delete = 0 unless defined($is_delete);

    my ($user_char_id, $item_char_id);
    if ($self->{use_user_char_id}) {
        $user_char_id = $user_id; undef($user_id);
        $self->sql('insert_user_char_id')->execute($user_char_id) or db_error;
    }
    if ($self->{use_item_char_id}) {
        $item_char_id = $item_id; undef($item_id);
        $self->sql('insert_item_char_id')->execute($item_char_id) or db_error;
    }

    $self->sql('insert_uninterested_buffer')->execute($user_id, $user_char_id, $item_id, $item_char_id, $is_delete)
        or db_error;
}

sub delete_pick {
    my ($self, $user_id, $item_id) = @_;
    $self->insert_uninterested($user_id, $item_id, 1);
}


sub insert_rating {
    my ($self, $user_id, $item_id, $rating, $is_delete) = @_;

    $is_delete = 0 unless defined($is_delete);

    my ($user_char_id, $item_char_id);
    if ($self->{use_user_char_id}) {
        $user_char_id = $user_id; undef($user_id);
        $self->sql('insert_user_char_id')->execute($user_char_id) or db_error;
    }
    if ($self->{use_item_char_id}) {
        $item_char_id = $item_id; undef($item_id);
        $self->sql('insert_item_char_id')->execute($item_char_id) or db_error;
    }

    $self->sql('insert_ratings_buffer')->execute($user_id, $user_char_id, $item_id, $item_char_id, $rating, $is_delete)
        or db_error;
}

sub delete_rating {
    my ($self, $user_id, $item_id, $rating) = @_;
    $self->insert_rating($user_id, $item_id, $rating, 1);
}


sub insert_tag {
    my ($self, $tag_id, $user_id, $item_id, $is_delete) = @_;

    $is_delete = 0 unless defined($is_delete);

    my ($user_char_id, $item_char_id);
    if ($self->{use_user_char_id}) {
        $user_char_id = $user_id; undef($user_id);
        $self->sql('insert_user_char_id')->execute($user_char_id) or db_error;
    }
    if ($self->{use_item_char_id}) {
        $item_char_id = $item_id; undef($item_id);
        $self->sql('insert_item_char_id')->execute($item_char_id) or db_error;
    }

    $self->sql('insert_tags_buffer')->execute($tag_id, $user_id, $user_char_id, $item_id, $item_char_id, $is_delete)
        or db_error;
}

sub delete_tag {
    my ($self, $tag_id, $user_id, $item_id) = @_;
    $self->insert_tag($tag_id, $user_id, $item_id, 1);
}

sub insert_category {
    my ($self, $category_id, $item_id, $is_delete) = @_;

    $is_delete = 0 unless defined($is_delete);

    my ($item_char_id);
    if ($self->{use_item_char_id}) {
        $item_char_id = $item_id; undef($item_id);
        $self->sql('insert_item_char_id')->execute($item_char_id) or db_error;
    }

    $self->sql('insert_categories_buffer')->execute($category_id, $item_id, $item_char_id, $is_delete)
        or db_error;
}

sub delete_category {
    my ($self, $category_id, $item_id) = @_;
    $self->insert_category($category_id, $item_id, 1);
}


# bin/flush_buffers.pl から呼び出す用
sub flush_buffers {
    my ($self, $flush_table) = @_;

    my $fields = {
        picks => [qw(user_id item_id timestamp)],
        uninterested => [qw(user_id item_id timestamp)],
        ratings => [qw(user_id item_id rating timestamp)],
        tagged_relations => [qw(tag_id user_id item_id timestamp)],
        categories => [qw(item_id category_id timestamp)],
    };
    my $delete_key_fields = {
        picks => [qw(user_id item_id)],
        uninterested => [qw(user_id item_id)],
        ratings => [qw(user_id item_id)],
        tagged_relations => [qw(tag_id user_id item_id)],
        categories => [qw(item_id category_id)],
    };
    my $update_fields = {
        ratings => [qw(rating)],
    };

    for my $table (keys(%$fields)) {
        next if ($flush_table and ($table ne $flush_table));

        $self->{out_table} = $table;
        $self->{buffer_table} = $table.'_buffer';
        $self->{fieldslist} = join(',', @{$fields->{$table}});
        $self->{delete_fieldslist} =  join(' and ', map "tgt.$_ = src.$_" , @{$delete_key_fields->{$table}});

        ## *_buffer テーブルがなければスキップ
        next unless $self->check_if_any_row_returned(
            $self->sql('check_table_existance'),
            $self->{buffer_table},
        );

        $self->{update_clause} = '';
        if ($update_fields->{$table}) { ## on duplicate key 付きの場合
            $self->{update_clause} = 'on duplicate key update '
                . join(',',
                       map {
                           (($self->{on_duplicate_entry} eq 'accumulate') and qq{$_ = $self->{out_table}.$_ + src.$_})
                               or (($self->{on_duplicate_entry} eq 'first') and qq{$_ = $self->{out_table}.$_})
                               or (qq{$_ = src.$_})
                           } @{$update_fields->{$table}}
                       );
        }

        my ($max_id) = $self->select_singlerow_array(
            $self->sql('flush_buffer1'),
        );
        if ($max_id) {
            # $LOGGER->debug("flushing $self->{buffer_table} up to id $max_id");
            if ($self->{use_user_char_id} and $self->_find_column_in_buffer_table('user_id')) {
                $self->sql('resolve_user_ids')->execute($max_id) or db_error;
            }
            if ($self->{use_item_char_id} and $self->_find_column_in_buffer_table('item_id')) {
                $self->sql('resolve_item_ids')->execute($max_id) or db_error;
            }

            eval {
                $self->sql('flush_buffer2_insert')->execute($max_id);
                $self->sql('flush_buffer2_delete')->execute($max_id);
                $self->sql('flush_buffer3')->execute($max_id);
            };
            $LOGGER->info($@) if $@; # 解析のためにロックかかってて失敗するのは構わない
        }
    }
}

sub cleanup {
    my ($self) = @_;

    eval {
        if ($self->{discard_user_id_char2int}) { $self->sql('cleanup_user_id_char2int')->execute }
        if ($self->{discard_item_id_char2int}) { $self->sql('cleanup_item_id_char2int')->execute }
        if ($self->{discard_picks}) { $self->sql('cleanup_picks')->execute }
        if ($self->{discard_uninterested}) { $self->sql('cleanup_uninterested')->execute }
        if ($self->{discard_ratings}) { $self->sql('cleanup_ratings')->execute }
    };
    $LOGGER->info($@) if $@; # 解析のためにロックかかってて失敗するのは構わない
}

sub _find_column_in_buffer_table {
    my ($self, $column) = @_;

    my $sth = $self->sql('check_buffer_columns');
    $sth->execute;
    while (my $row = $sth->fetchrow_hashref) {
        if ($row->{Field} eq $column) {
#            $LOGGER->warn("found $column");
            return 1;
        }
    }
    return 0;
}

1;
