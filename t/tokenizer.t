# -*- cperl -*-

use Test::More tests => 1 + 9;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

#exit;

use locale;

$a = '«·È';

SKIP: {
  skip "not a good locale", 15 unless $a =~ m!^\w{3}$!;

  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T, "t/tests.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);

    my $tok1 = Lingua::PT::PLNbase::tokeniza($input); # Diana
    is($tok1, $output);

  }
  close T;
}

1;


