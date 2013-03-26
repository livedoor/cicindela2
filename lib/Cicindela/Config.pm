package Cicindela::Config;
use strict;
use base qw(Class::Singleton);

use Tie::Hash;
use base 'Tie::StdHash';
use Carp ();
use vars qw($AUTOLOAD);

sub case_sensitive { 0 }

our $setenv_sh ="/etc/Cicindela-conf.pl";

sub _new_instance {
    my $class = shift;
    if (!defined $ENV{CICINDELA_CONFIG_NAME} and -x $setenv_sh) {
        do $setenv_sh or warn $!;
    }
    $class->new($ENV{CICINDELA_CONFIG_NAME});
}

sub new {
    my $pkg = shift;
    $pkg->TIEHASH(@_);
}

sub as_hashref {
    my $self = shift;
    return 
        {map { lc($_) => $self->{$_}, uc($_) => $self->{$_}} keys %$self};
}

sub safe_load {
    my $module = shift;
    $module =~ /^([A-Za-z0-9_\:]+)$/;
    $module = $1;
    eval qq{require $module};
}

sub TIEHASH {
    my($class, $configname) = @_;

    no strict 'refs';
    local $@;

    my $common_name = $ENV{EDGE_CONFIG_COMMON_NAME} || '_common';
    safe_load("${class}::${common_name}");
    die $@ if $@ && $@ !~ /Can\'t locate/;
    if ($configname) {
        safe_load("${class}::${configname}");
        die $@ if $@ && $@ !~ /Can\'t locate/;
    }
    my %config = %{join '::', $class, $common_name, 'Config'};
    %config = (%config, %{join '::', $class, $configname, 'Config'}) if $configname;

    # case sensitive hash
    %config = map { lc($_) => $config{$_} } keys %config
        unless $class->case_sensitive;
    bless \%config, $class;
}

sub FETCH {
    my($self, $key) = @_;
    unless (ref($self)) {
        require Carp;
        Carp::carp "Possibly misuse: $key called as a class method.";
    }
    $key = lc($key) unless $self->case_sensitive;
    Carp::croak "no such key: $key"
        if (! exists $self->{$key} && $self->strict_param);
    $self->{$key};
}

sub STORE {
    my($self, $key, $value) = @_;
    $key = lc($key) unless $self->case_sensitive;
    Carp::croak "can't modify param $key"
        unless $self->can_modify_param;
    $self->{$key} = $value;
}

sub param {
    my $self = shift;
    if (@_ == 0) {
        return keys %{$self};
    }
    elsif (@_ == 1) {
        my $value = $self->FETCH(@_);
        if (wantarray && ref($value)) {
            return @$value if ref($value) eq 'ARRAY';
            return %$value if ref($value) eq 'HASH';
        }
        return $value;
    }
    else {
        $self->STORE(@_);
    }
}

# nop for AUTOLOAD
sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://;

    # cache accessor
    $self->_create_accessor($AUTOLOAD);

    $self->param($AUTOLOAD, @_);
}

sub _create_accessor {
    my($self, $accessor) = @_;

    no strict 'refs';
    my $class = ref $self;
    *{"$class\::$accessor"} = sub {
        my $self = shift;
        $self->param($accessor, @_);
    };
}

1;
__END__

1;
