package Cicindela::Handlers::Record;

# $Id: Record.pm 10 2008-12-23 20:54:39Z tsukue $

use strict;
use mod_perl;
use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} and 
		     $ENV{MOD_PERL_API_VERSION} >= 2);
use Cicindela::Config::MixIn;
use Cicindela::IncomingData;

BEGIN {
    if (MP2) {
        require Apache2::Const;
        Apache2::Const->import(-compile => qw(:common :http));
	require Apache2::RequestRec;
	require Apache2::RequestIO;
    }
    else {
        require Apache::Constants;
        Apache::Constants->import(qw(:common :http));
    }
}

our $INSERTERS;

sub handler {
    my $r = shift;

    my %q;
    if (MP2) {
	%q = map { split(/=/, $_) } split(/&/,$r->args);
    } else {
	%q = $r->args;
    }

    my $d;
    if ($q{set}) {
        $d = $INSERTERS->{$q{set}};
        unless ($d) {
            eval {
                $d = new Cicindela::IncomingData(
                    set_name => $q{set},
                    %{config->settings->{$q{set}}}
                );
            };
	    if ($@ or !$d) {
		return MP2 ? Apache2::Const::HTTP_BAD_REQUEST : Apache::Constants::HTTP_BAD_REQUEST;
	    }

            $INSERTERS->{$q{set}} = $d;
        }
    }

    if ($q{op} eq 'insert_pick'
            and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->insert_pick($q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'insert_uninterested'
                 and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->insert_uninterested($q{user_id}, $q{item_id}, $q{rating});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'insert_rating'
                 and defined($q{user_id}) and defined($q{item_id}) and defined($q{rating})) {
        eval {
            $d->insert_rating($q{user_id}, $q{item_id}, $q{rating});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'insert_tag'
                 and defined($q{tag_id}) and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->insert_tag($q{tag_id}, $q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'set_category'
                 and defined($q{category_id}) and defined($q{item_id})) {
        eval {
            $d->insert_category($q{category_id}, $q{item_id});
        }; warn $@ if $@;
    }

    # delete系
    elsif ($q{op} eq 'delete_pick'
            and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->delete_pick($q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'delete_uninterested'
                 and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->delete_uninterested($q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'delete_rating'
                 and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->delete_rating($q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'delete_tag'
                 and defined($q{tag_id}) and defined($q{user_id}) and defined($q{item_id})) {
        eval {
            $d->delete_tag($q{tag_id}, $q{user_id}, $q{item_id});
        }; warn $@ if $@;
    } elsif ($q{op} eq 'remove_category'
                 and defined($q{category_id}) and defined($q{item_id})) {
        eval {
            $d->delete_category($q{category_id}, $q{item_id});
        }; warn $@ if $@;
    }

    # no match
    else {
	return MP2 ? Apache2::Const::HTTP_BAD_REQUEST : Apache::Constants::HTTP_BAD_REQUEST;
    }

    return MP2 ? Apache2::Const::HTTP_NO_CONTENT : Apache::Constants::HTTP_NO_CONTENT;
#    return MP2 ? Apache2::Const::OK : Apache::Constants::OK;
}

1;
