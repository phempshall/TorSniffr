#!/usr/bin/env perl -T

use strict;
use warnings;
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/../lib";

use TorSniffr;
TorSniffr->to_app;
