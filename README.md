# TorSniffr

Test any Tor onion URL and check the HTTP response. TorSniffr is a web-sniffer.net/TestURI.org alternative for onion land.

[https://www.torsniffr.com](https://www.torsniffr.com/)

![Screenshot of TorSniffr](/screenshot-www.torsniffr.com-2023.02.27-19_28_08.png?raw=true "TorSniffr Screenshot")

## Caution

**This application installs and connects to the Tor network. If this is a problem for you or your country, do not use this software.**

## Docker Build

It's recommended to use Docker to make things easier.

Build with
`docker build -t torsniffr .`

Run with
`docker run --name torsniffr -p 80:8080 torsniffr`

Access via your web browser
`http://localhost`

## Manual Build

Install Perl and the following cpan modules:

- Net::Server@2.012
- Dancer2
- *Starman*
- Modern::Perl
- FindBin
- Template
- LWP@6.68
- LWP::Protocol::socks
- HTTP::Headers
- HTTP::Response
- Compress::Zlib
- Time::HiRes
- URI::Encode
- HTML::Entities

Launch with Starman (or use another [PSGI/Plack implementation](https://plackperl.org/))

`starman -E production --port 8080 TorSniffr/bin/app.psgi &`

## Build/Runtime Problems

Updates to the Perl modules can sometimes break the building or running of this application. Currently there are two known issues with the following modules. These modules in the Dockerfile have been forced to older versions:

- Net::Server@2.012 (issue [145672](https://rt.cpan.org/Public/Bug/Display.html?id=145672))
- LWP@6.68 (libwww-perl issue [431](https://github.com/libwww-perl/libwww-perl/issues/431))

## Disclaimer

```
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

## License

```
TorSniffr
https://www.torsniffr.com
Copyright (C) 2015-2023 Paul Hempshall.

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
```