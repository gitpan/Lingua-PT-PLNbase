# -*- cperl -*-

use Test::More tests => 1 + 10 * 6;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

use locale;

$a = '���';

SKIP: {
  skip "not a good locale", 10 * 6 unless $a =~ m!^\w{3}$!;

  my %words = qw/m� ma
		 r� re
		 cora��o coracao
		 b�b� bebe
		 h� ha
		 � a
		 centr�foga centrifoga
		 c�caras cocaras
		 c�mulo cumulo
		 ca�a caca/;
  for (keys %words) {
    ok(has_accents($_));
    ok(!has_accents($words{$_}));
    ok(has_accents(uc($_)));

    is(remove_accents($_), $words{$_});
    is(remove_accents($words{$_}), $words{$_});
    is(remove_accents(uc($_)), uc($words{$_}));
  }

}

1;


