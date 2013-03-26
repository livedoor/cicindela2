package Cicindela::Config::_common;
use strict;
use vars qw(%C);
*Config = \%C;

$C{CICINDELA_HOME} = '/home/cicindela';
$C{LOG_CONF} = $C{CICINDELA_HOME}. '/etc/log.conf';
$C{FILTERS_NAMESPACE} = 'Cicindela::Filters';

$C{DEFAULT_DATASOURCE} = [ 'dbi:mysql:cicindela;host=localhost', 'cicindela', 'japana' ];

$C{SETTINGS} = {

    ##
    ## sample settings for ldclip_dataset
    ##

#    # simple setting
#    'clip_simple' => {
#        datasource =>  [ 'dbi:mysql:cicindela_clip_db;host=localhost', 'cicindela', 'japana' ],
#        filters => [
#            [ 'PicksExtractor', { interval => '20 year' } ],
#            'InverseUserFrequency',
#            'ItemSimilarities',
#        ],
#        recommender => 'ItemSimilarities',
#        calculation_track => 1,
#        refresh_interval => 1,
#    },
#
#    # assume tag_ids as pseudo user_ids to obtain tag-oriented item similarities
#    'clip_tags' => {
#        datasource =>  [ 'dbi:mysql:cicindela_clip_db;host=localhost', 'cicindela', 'japana' ],
#        filters => [
#            [ 'CopyPicks::TagId2UserId', {
#                interval => '20 year',
#                in_table_picks => 'picks',
#                out_table => 'picks_from_tags',
#            } ],
#            [ 'PicksExtractor', {
#                interval => '20 year',
#                in_table => 'picks_from_tags',
#                out_table => 'extracted_picks_from_tags',
#            } ],
#            [ 'InverseUserFrequency', {
#                in_table => 'extracted_picks_from_tags',
#                out_table => 'iuf_from_tags',
#            } ],
#            [ 'ItemSimilarities', {
#                in_table => 'extracted_picks_from_tags',
#                in_table_iuf => 'iuf_from_tags',
#                out_table => 'item_similarities_from_tags',
#            } ],
#        ],
#        recommender => [ 'ItemSimilarities', { in_table => 'item_similarities_from_tags_online' } ],
#        calculation_track => 2,
#        refresh_interval => 1,
#    },
#
#    # mix the above two settings by 6:4
#    'clip_hybrid' => {
#        datasource =>  [ 'dbi:mysql:cicindela_clip_db;host=localhost', 'cicindela', 'japana' ],
#        recommender => [ 'Hybrid', {
#            settings => [
#                { factor => 0.6, set_name => 'clip_simple' },
#                { factor => 0.4, set_name => 'clip_tags' },
#            ]
#        } ],
#    },


    ##
    ## sample settings for movielens dataset
    ##

#    # recommendtaion by ItemSimilarities::WithRatings module
#    'movielens' => {
#        datasource =>  [ 'dbi:mysql:cicindela_movielens_db;host=localhost', 'cicindela', 'japana' ],
#        filters => [
#            'CopyPicks::WithRatings',
#            'RatingsConverter::FixedCenter',
#            [ 'PicksExtractor::WithRatings', {
#                 interval => '20 year',
#                 in_table => 'converted_ratings',
#                 threshold1 => 3,
#                 limit1 => 5000000,
#             } ],
#            [ 'InverseUserFrequency', {
#                in_table => 'extracted_ratings',
#            } ],
#            [ 'ItemSimilarities::WithRatings', {
#                 use_iuf => 1,
#                 order_by => 'log(count)/log(10) * abs(score) desc',
#             } ],
#        ],
#        recommender => 'ItemSimilarities::WithRatings',
#        calculation_track => 3,
#        refresh_interval => 1,
#     },
#
#    # alternate setting with SlopeOneDiffs module
#     'movielens' => {
#        datasource =>  [ 'dbi:mysql:cicindela_movielens_db;host=localhost', 'cicindela', 'japana' ],
#        filters => [
#             'CopyPicks::WithRatings',
#             'RatingsConverter::FixedCenter',
#             'RatingsConverter::InverseUserFrequency',
#             [ 'PicksExtractor::WithRatings', {
#                 interval => '20 year',
#                 in_table => 'converted_ratings',
#                 threshold1 => 3,
#                 limit1 => 5000000,
#             } ],
#             'SlopeOneDiffs',
#         ],
#        recommender =>'SlopeOneDiffs',
#        calculation_track => 3,
#        refresh_interval => 1,
#     },


};

# for using cleanup_mysql_binlog.pl
$C{DB_MAINTENANCE_SETS} = [
    {
        master => [ 'dbi:mysql:host=localhost', 'maintenance', '' ],
        slave => [],
    },
];

1;
