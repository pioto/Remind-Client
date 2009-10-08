use warnings;
use strict;

use Test::More tests => 2;

use File::Spec;
use FindBin;

my $REMIND = 'remind';
my $TEST_REMINDERS = File::Spec->catfile($FindBin::Bin, '000_reminders');

ok my $rem = `$REMIND -n $TEST_REMINDERS`, 'can run test reminder';
if ($? || !$rem) {
    BAIL_OUT("Failed to run a test $REMIND command. Is remind installed?");
}

like $rem, qr#^\d{4}/\d\d/\d\d it works!$#, 'test reminder output valid';

