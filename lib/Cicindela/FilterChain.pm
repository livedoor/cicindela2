package Cicindela::FilterChain;

use strict;
use base qw(Ima::DBI);
use Time::HiRes qw(gettimeofday tv_interval);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

use Module::Pluggable require => 1, search_path => [config->filters_namespace];

our $LOGGER = init_logger(config->log_conf, 1);

# require all plugins
our @ALL_PLUGINS = __PACKAGE__->plugins;

sub new {
    my ($class, $set_name) = @_;

    $set_name ||= 'default';
    my $self = bless {
        datasource => '',
        filters => [],

        set_name => $set_name,
        %{config->settings->{$set_name}},
    }, $class;

    __PACKAGE__->set_db('main', @{$self->{datasource}});

    $self->_prepare_filters;

    return $self;
}

sub _prepare_filters {
    my $self = shift;

    my @filter_instances;
    for my $filter (@{$self->{filters}}) {
        # set filter init arguments
        my $args;
        if (ref($filter) eq 'ARRAY') {
            ($filter, $args) = @$filter;
        }
        for (qw(datasource slave_datasource set_name)) {
            $args->{$_} = $self->{$_} if $self->{$_}
        }

        # instanciate filters
        my $full_namespace = join('::', config->filters_namespace, $filter);
        if (member_of($full_namespace, @ALL_PLUGINS)) {
            push @filter_instances, $full_namespace->new(%$args);
        } else {
            $LOGGER->warn("filter $full_namespace not loaded");
        }
    }
    $self->{_filter_instances} = \@filter_instances;
}

sub process {
    my $self = shift;

    # create necessary tables & do process
    for my $filter (@{$self->{_filter_instances}}) {
        $LOGGER->info("calling ".$filter->short_name);
        $filter->create_tables;

        my $t0 = [gettimeofday];
        $filter->process;
        $LOGGER->info($filter->short_name." done. (".tv_interval($t0)."sec.)");
    }

    # make tables online
    my @rename_tables;
    for my $filter (@{$self->{_filter_instances}}) {
        my $swap_tables = $filter->online_swaps;
        next unless $swap_tables;
        while (scalar @$swap_tables) {
            my $table1 = shift @$swap_tables;
            my $table2 = shift @$swap_tables;
            push @rename_tables, ("$table1 to temp", "$table2 to $table1", "temp to $table2");
        }
    }
    __PACKAGE__->db_main->do(q{rename table }. join(',', @rename_tables)) if @rename_tables;

    # cleanup
    for my $filter (@{$self->{_filter_instances}}) {
        $filter->cleanup;
    }
}

1;
