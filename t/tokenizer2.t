# -*- cperl -*-

use Test::More tests => 1 + 16 ;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

use locale;

$a = '«·È';

$i = 0;
SKIP: {
  skip "not a good locale", 16 unless $a =~ m!^\w{3}$!;

  $i++;
  $/ = "\n\n";

  my $input = "";
  my $output = "";
  open T, "t/tests2.tok" or die "Cannot open tests file";
  while(<T>) {
    chomp($input = <T>);
    chomp($output = <T>);


    my $tok2 = atomiza($input); # Braga
    is($tok2, $output);
  exit if $i == 14;
  }
  close T;
}

1;


