#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

use String::Range::Expand qw(expand_range);

# Autoflush ON
local $| = 1;

# Test Expansion
is_deeply(
    [ expand_range('host[aa-ad,^ab][01-04,^02-03].name') ],
    [
        'hostaa01.name', 'hostaa04.name', 'hostac01.name', 'hostac04.name',
        'hostad01.name', 'hostad04.name',
    ],
    "Expansion OK!",
);

# Done
done_testing();
exit 0;
