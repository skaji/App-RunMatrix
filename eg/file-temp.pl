#!/usr/bin/env perl
use strict;
use warnings;
use File::Temp ();

my ($fh, $name) = File::Temp::tempfile(TEMPLATE => "test-XXXXX", UNLINK => 1);
print $name, "\n";
