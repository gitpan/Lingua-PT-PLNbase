# -*- cperl -*-

use Test::More tests => 1 + 2;

use locale;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }


$a = 'Çáé';

SKIP: {
  skip "not a good locale", 2 unless $a =~ m!^\w{3}$!;

  fsentences({output=>'foo'},"t/ftext1");
  is(`diff foo t/ftext1.out1`,"");
  unlink "foo";


  fsentences({s_tag => 'sentence',
	      t_tag => 'file',
	      p_tag => 'paragraph',
	      output=>'foo'},"t/ftext1");
  is(`diff foo t/ftext1.out2`,"");
  unlink "foo";
}
