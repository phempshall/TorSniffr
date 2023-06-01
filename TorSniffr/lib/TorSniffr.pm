###########################################################

package TorSniffr;
use strict;
use warnings;
use Modern::Perl;
use Template;
use Dancer2;
use TorSniffr::Sniffr;

our $VERSION = '0.3';

###########################################################

get '/' => sub {
    template 'index';
};

get '/sniffer/?' => sub {
    redirect '/';
};

post '/sniffer/' => sub {
	if (params->{'form-url'}) {

		unless (checkInput(params->{'form-url'})) {
			redirect '/';
		}

		my $redirect;
		if (params->{'form-redirect'}) {
			$redirect = 1;
		}

		my $sniff = TorSniffr::Sniffr->new(
			scalar params->{'form-url'},
			scalar $redirect
		);

		$sniff->Setup();
		$sniff->Request();

		if (defined $sniff->{warning_critical}) {
			template 'failed.tt', {
				sniff => $sniff
			};
		}
		else {
			template 'results.tt', {
				sniff => $sniff
			};
		}
	}
	else { 
		redirect '/'; 
	}
};


sub checkInput {
	my $input = shift;

	$input =~ s/^\s+|\s+$//g;

	if ($input !~ m/^(?:(http(?:s)?:\/\/)){0,1}(?:[a-z0-9\-]+\.){0,}?(?:(?:[a-z2-7]{16})|(?:[a-z2-7]{56}))\.onion(?!\/)?(\/.*)?$/) {
		return 0;
	}

	return 1;
}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

TorSniffr.pm

=head1 SYNOPSIS

Dancer2 routes for TorSniffr application

=head1 LICENSE

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

Paul Hempshall - <https://www.paulhempshall.com>

=head1 COPYRIGHT

Copyright 2015-2021 Paul Hempshall

=head1 DESCRIPTION

=over

=item get/post

Dancer2 routes for homepage and sniffer

- Check input params, see item L<checkInput()|"checkInput()">

- Create L<TorSniffr::Sniffr/new>

- Setup the new class L<TorSniffr::Sniffr/Setup>

- Send request using L<TorSniffr::Sniffr/Request>

- Print results/warnings from L<TorSniffr::Sniffr> class to L<Template>

=back

=over

=item checkInput()

This function does basic regex matching on the input URL and
returns false if it does not match

http://blog.erratasec.com/2014/07/xkeyscore-regex-foo.html#.VySYI_krLg4
/(?:([a-z]+):\/\/){0,1}([a-z2-7]{16})\.onion(?::(\d+)){0,1}/c
 
Regex update to include sub-domains
(?:([a-z]+):\/\/){0,1}(?:[a-z0-9\-]+\.){0,}?([a-z2-7]{16})\.onion(?::(\d+)){0,1}

(?:([a-z]+):\/\/){0,1}(?:[a-z0-9\-]+\.){0,}?([a-z2-7]{16,56})\.onion(?::(\d+)){0,1}

2022 V3 support with subdomains
(?:([a-z]+):\/\/){0,1}(?:[a-z0-9\-]+\.){0,}?([a-z2-7]{16,56})\.onion(?::(\d+)){0,1}(?:\/(?:[^\s]+)?){0,1}

=back

=over

=cut