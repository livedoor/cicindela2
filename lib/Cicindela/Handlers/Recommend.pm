package Cicindela::Handlers::Recommend;

# $Id: Recommend.pm 10 2008-12-23 20:54:39Z tsukue $

use strict;
use mod_perl;
use constant MP2 => (exists $ENV{MOD_PERL_API_VERSION} and 
		     $ENV{MOD_PERL_API_VERSION} >= 2);
use Cicindela::Config::MixIn;
use Cicindela::Recommender;

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

our $RECOMMENDERS;

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
        $d = $RECOMMENDERS->{$q{set}};
        unless ($d) {
            $d = Cicindela::Recommender->get_instance_for_set($q{set});
	    unless ($d) {
		return MP2 ? Apache2::Const::HTTP_BAD_REQUEST : Apache::Constants::HTTP_BAD_REQUEST;
	    }

            $RECOMMENDERS->{$q{set}} = $d;
        }
    }

    my $optional_fields = { map { $_ => $q{$_} } qw(limit category_id) };
    if ($q{op} eq 'for_item') {
        eval {
            output_list($r, $d->output_recommend_for_item($q{item_id}, $optional_fields) );
        }; warn $@ if $@;
    } elsif ($q{op} eq 'for_user') {
        eval {
            output_list($r, $d->output_recommend_for_user($q{user_id}, $optional_fields) );
        }; warn $@ if $@;
    } elsif ($q{op} eq 'similar_users') {
        eval {
            output_list($r, $d->output_similar_users($q{user_id}, $optional_fields) );
        }; warn $@ if $@;
    } else {
	return MP2 ? Apache2::Const::HTTP_BAD_REQUEST : Apache::Constants::HTTP_BAD_REQUEST;
    }

    return MP2 ? Apache2::Const::OK : Apache::Constants::OK;
}

sub output_list {
    my ($r, $list) = @_;

    $r->content_type('text/plain');
    $r->send_http_header unless (MP2);
    $r->print(join("\n", @$list)."\n");
}

1;
