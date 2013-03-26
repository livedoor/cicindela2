package Cicindela::DBI;

# $Id: DBI.pm 10 2008-12-23 20:54:39Z tsukue $

use strict;
use base qw(Ima::DBI);
use Cicindela::Config::MixIn;
use Cicindela::Utils qw(:standard);

our $LOGGER = init_logger(config->log_conf, 1);


## core base class methods

sub new {
    my $class = shift;

    my $self = bless {
        set_name => 'default',
#        datasource => [],
#        slave_datasource => [],

        @_,
    }, $class;

    $self->_set_datasources;
    $self->_set_sqls;

    return $self;
}

sub _set_datasources {
    my $self = shift;

    __PACKAGE__->set_db($self->_master_db_name, @{$self->{datasource}}, {
        AutoCommit => 1, ShowErrorStatement => 1,
    } );
    __PACKAGE__->set_db($self->_slave_db_name, @{$self->{slave_datasource}}, {
        AutoCommit => 1, ShowErrorStatement => 1,
    } ) if $self->{slave_datasource};
}


sub _master_db_name { shift->{set_name} }

sub _slave_db_name {
    my $self = shift;
    return $self->{set_name}.'-slave' if $self->{slave_datasource};
}


sub _set_sqls {
    my $self = shift;
    my $sqls = $self->sqls;
    return unless $sqls;

    my $class = ref($self);
    while (my ($name, $stmt) = each(%$sqls)) {
        $LOGGER->debug("setting sql: class=$class : ".$self->_sql_name($name) .' -> '. $stmt);
        $class->set_sql($self->_sql_name($name), $stmt, $self->_master_db_name);

        $LOGGER->debug("setting sql: class=$class : ".$self->_slave_sql_name($name) .' -> '. $stmt);
        $class->set_sql($self->_slave_sql_name($name), $stmt, $self->_slave_db_name) if $self->_slave_db_name;
    }
}


sub _sql_name {
    my ($self, $name) = @_;
    return join('__', $self->_master_db_name, $name);
}

sub _slave_sql_name {
    my ($self, $name) = @_;
    return join('__', $self->_slave_db_name, $name) if $self->_slave_db_name;
}


# extend Ima::DBI

sub master_dbh {
    my ($self) = @_;
    my $db_name = 'db_' . $self->_master_db_name;
    my $class = ref($self);
    return $class->$db_name if $class->UNIVERSAL::can($db_name);
}

sub slave_dbh {
    my ($self) = @_;
    my $db_name = 'db_' . $self->_slave_db_name;
    my $class = ref($self);
    return $class->$db_name if $class->UNIVERSAL::can($db_name);
}


sub sql {
    my ($self, $name, @args) = @_;
    my $sql_name = 'sql_' . $self->_sql_name($name);
    my $class = ref($self);
    return $class->$sql_name($self, @args) if $class->UNIVERSAL::can($sql_name);
}

sub slave_sql {
    my ($self, $name, @args) = @_;
    return $self->sql($name, @args) unless $self->_slave_db_name;

    my $sql_name = 'sql_' . $self->_slave_sql_name($name);
    my $class = ref($self);
    return $class->$sql_name($self, @args) if $class->UNIVERSAL::can($sql_name);
}


sub transform_sql {
    my ($class, $sql, @args) = @_;

    if (ref($args[0])) {
        my $obj = shift(@args);
        $sql =~ s/%\&([\w]+)/$obj->$1/ge;
        $sql =~ s/%\$([\w]+)/$obj->{$1}/ge;
    }
    $sql = $class->SUPER::transform_sql($sql, @args);

    $LOGGER->debug("preparing sql: $sql");
    return $sql;
}

# handy shortcuts

sub select_singlerow_array {
    my $self = shift;
    my $sth = shift;

    my @row;
    $sth->execute(@_) or db_error;
    @row = $sth->fetchrow_array;
    $sth->finish;
    return @row
}

sub check_if_any_row_returned {
    my $self = shift;
    my $sth = shift;

    my $flag = 0;
    $sth->execute(@_) or db_error;
    $flag = 1 if ($sth->fetchrow_arrayref);
    $sth->finish;

    return $flag;
}


## abstract methods

sub sqls { }


1;
