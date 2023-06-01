###########################################################
package TorSniffr::Sniffr;
use strict;
use warnings;
use Modern::Perl;
use LWP::UserAgent;
use Compress::Zlib;
use Time::HiRes qw(gettimeofday);
use URI::Encode qw(uri_encode uri_decode);
use HTML::Entities;
use Dancer2;

our $VERSION = '0.3';

###########################################################

sub new {
	my $class = shift;
	$class = ref $class if ref $class;

	my ($input, $redirect) = (@_);
	my $self = {
		input				=> $input,
		redirect			=> $redirect,
		host				=> undef,
		uri					=> undef,
		protocol			=> undef,
		request_headers		=> undef,
		request_message		=> undef,
		resp_headers		=> undef,
		response_message	=> undef,
		response_content	=> undef,
		response_time		=> undef,
		response_size		=> undef,
		warning_exceeded	=> undef,
		warning_critical	=> undef,
		parsed_data			=> undef
	};
	
	bless $self, $class;
	return $self;
}

###########################################################

sub Setup {
	my $self = shift;

	if ($self->{input} =~ m/https:\/\//) { $self->{protocol} = 'https'; }
	else { $self->{protocol} = 'http'; }

	$self->{input} =~ s/^\s+|\s+$//g;
	($self->{host}) = $self->{input} =~ m/(\b[\-\.0-9a-z]+\.onion(?![_\-0-9a-z])\b)/;

	($self->{uri}) = $self->{input} =~ m/$self->{host}(.*)/;
	if ($self->{uri} eq "") { $self->{uri} = "/"; }

	$self->{uri} = uri_encode($self->{uri});
}

sub Request {
	my $self = shift;

	my $request_headers = HTTP::Headers->new(
		Accept 			=> 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		Accept_Language => 'en-gb,en;q=0.5',
		Accept_Encoding => 'gzip, deflate',
		Accept_Charset 	=> 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
		Connection 		=> 'close',
		Cache_Control 	=> 'no-cache',
		DNT 			=> '1'
	);

	my $agent = LWP::UserAgent->new(
		default_headers		=> $request_headers,
		# max_size 			=> '512000',
		max_redirect 		=> $self->{redirect} ? '7' : '0',
		protocols_allowed	=> ['http', 'https'],
		ssl_opts 			=> { verify_hostname => 0 },
		timeout				=> '30',
		agent 				=> 'Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0',
		cookie_jar 			=> {}
	);
	
	# Tor proxy
	$agent->proxy(['http', 'https'], 'socks://127.0.0.1:9050');

	# Send the request ($response) and populate request duration ($start and $end)
	my $start = gettimeofday;
	my $response = $agent->get($self->{protocol} . '://' . $self->{host} . $self->{uri});
	my $end = gettimeofday;

	# Set error message and return to template if $response is not successful
	unless ($response->is_success) {
		if ($response->status_line =~ m/500/) {
			$self->{warning_critical} = $response->status_line;
			return 1;
		}
	}

	# Deal with response headers
	my $responseHeaders = $response->headers();

	foreach my $value (keys %$responseHeaders) {
		# Set warnings for exceeding response size limit
		if ($value eq 'client-aborted' && $responseHeaders->{$value} eq 'max_size') {
			$self->{warning_exceeded} = true;
		}

		# Set response content-encoding
		if ($value eq 'content-encoding') {
			if ($responseHeaders->{$value} eq 'gzip') {
				$self->{response_encoding} = 'gzip';
			}
		}

		# Calculate content-length response size
		if ($value eq 'content-length') {
			$self->{response_size} = sprintf "%.2f", $responseHeaders->{$value} / 1024;
		}

		# Remove response headers that come from LWP
		if ($value =~ /::std_case|title|client\-/) { delete $responseHeaders->{$value}; next; }

		# Some headers return arrays. Loop array and concatenate into a string.
		if(ref($responseHeaders->{$value}) eq 'ARRAY'){
			#It's an array reference...
			#you can read it with $item->[1]
			#or dereference it uisng @newarray = @{$item}
			my $string;
			foreach my $item (@{$responseHeaders->{$value}}) {
				$string .= $item;
			}
			$responseHeaders->{encode_entities($value)} = encode_entities($string);
		}

		# Clean up response headers formatting
		if ($value =~ m/-/) {
			my @newValues = split('-',$value);
			for my $newValue (@newValues) {
				$newValue = ucfirst($newValue);
			}

			$responseHeaders->{encode_entities(join('-',@newValues))} = encode_entities($responseHeaders->{$value});
			delete $responseHeaders->{$value};
		}
		else {
			$responseHeaders->{encode_entities(ucfirst($value))} = encode_entities($responseHeaders->{$value});
			delete $responseHeaders->{$value};
		}
	}

	# Clean up request headers formatting
	foreach my $value (keys %$request_headers) {
		if ($value =~ m/-/) {
			my @newValues = split('-',$value);
			for my $newValue (@newValues) {
				$newValue = ucfirst($newValue);
			}

			$request_headers->{join('-',@newValues)} = $request_headers->{$value};
			delete $request_headers->{$value};
		}
		else {
			$request_headers->{ucfirst($value)} = $request_headers->{$value};
			delete $request_headers->{$value};
		}
	}

	# Create request message, eg: GET /page HTTP/1.1
	$self->{request_message} = join(' ', $response->request()->{'_method'}, encode_entities($self->{uri}), $response->{'_protocol'});
	
	# Add the cleaned up req/resp objects to main class
	$self->{request_headers} = $request_headers;
	$self->{resp_headers} = $responseHeaders;

	# Create response message, eg: HTTP/1.1 200 OK
	$self->{response_message} = join(' ', $response->{'_protocol'}, $response->{'_rc'}, $response->{'_msg'});

	# Calculate response time
	$self->{response_time} = sprintf "%.2f", $end - $start;

	# Deal with content-encoding
	if (defined $self->{response_encoding}) {
		if ($self->{response_encoding} eq 'gzip') {
			$self->{response_content} = Encode::decode_utf8(Compress::Zlib::memGunzip($response->decoded_content));
		}
	}
	else {
		$self->{response_content} =  Encode::decode_utf8($response->decoded_content);
	}

	# Strip < > from response_content
	$self->{response_content} =~ s/</&lt;/g;
	$self->{response_content} =~ s/>/&gt;/g;

	# Calculate the response payload size if not otherwise defined
	if (! defined $self->{response_size}) {
		use bytes;
		$self->{response_size} = sprintf "%.2f", bytes::length($self->{response_content}) / 1024;
	}

	# Calculate the response payload size if size has exceeded limit
	if (defined $self->{warning_exceeded}) {
		use bytes;
		$self->{warning_exceeded} = sprintf "%.2f", bytes::length($self->{response_content}) / 1024;
	}

	1;
}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

Sniffr.pm

=head1 SYNOPSIS

Main application functions for TorSniffr application

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

=item new()

New Sniffr class containing the object

	my $self = {
		input			=> shift,
		host			=> undef,
		uri			=> undef,
		protocol		=> undef,
		request_headers		=> undef,
		request_message		=> undef,
		resp_headers		=> undef,
		response_message	=> undef,
		response_content	=> undef,
		response_time		=> undef,
		response_size		=> undef,
		warning_exceeded	=> undef,
		warning_critical	=> undef
	};

=back

=over

=item Setup()

Setup the new class

- Set the protocol type C<https or http>, defaults to C<http>

	if ($self->{input} =~ m/https:\/\//) { $self->{protocol} = 'https'; }
	else { $self->{protocol} = 'http'; }

- Extract the host from input

	($self->{host}) = $self->{input} =~ m/(\b[\-\.0-9a-z]+\.onion(?![_\-0-9a-z])\b)/;

- Extract the URI from the input, add a missing / if not present and C<uri_encode>

	($self->{uri}) = $self->{input} =~ m/$self->{host}(.*)/;
	if ($self->{uri} eq "") { $self->{uri} = "/"; }
	$self->{uri} = uri_encode($self->{uri});

=back

=over

=item Request()

Create, Send, Retreive and Cleanup the Request

- Setup L<HTTP::Headers>

	my $request_headers = HTTP::Headers->new(
		Accept 			=> 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
		Accept_Language => 'en-gb,en;q=0.5',
		Accept_Encoding => 'gzip, deflate',
		Accept_Charset 	=> 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
		Connection 		=> 'close',
		Cache_Control 	=> 'no-cache',
		DNT 			=> '1',
		User_Agent 		=> "Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0"
	);

- Setup L<LWP::UserAgent>

	my $agent = LWP::UserAgent->new(
		default_headers		=> $request_headers,
		max_size 			=> '512000',
		max_redirect 		=> '0',
		protocols_allowed	=> ['http', 'https'],
		ssl_opts 			=> { verify_hostname => 0 },
		time_out			=> '3'
	);


B<The rest of this subroutine is commented in line - good luck>

=back

=cut