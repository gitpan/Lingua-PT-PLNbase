# -*- cperl -*-

use Test::More tests => 1 + 12;

use locale;

BEGIN { use_ok( 'Lingua::PT::PLNbase' ); }

my @ss = sentences(<<"EOT");
O dr. Jo�o Rat�o comeu a D. Carochinha.
O Eng. visitou a av. do Marqu�s.
O Ex. Sr. Ant�nio foi prof. de Matem�tica.
O Pe. Joaquim casou o Arq. Jo�o com a Prof�. Joana.
Os profs. v�o ao lg. do Pa�o.
Os profs. v�o ao lgo. do Pa�o.
As profas. tamb�m v�o ao lgo. do Pa�o.
No s�c. V A.C. j� n�o existiam dinossauros.
Os Exmos. Srs. deputados que...
Os Exmos. Srs. Drs. v�o almo�ar ao Snack-Bar.
Na rua Cel. Ant�nio virar � esquerda, pela avenida do Sen. Joaquim.
A empresa de Marco Correia e Cia. Lda. fica na Trv. M�rio Soares.
EOT

my $i = 0;
my @sts = (q/O dr. Jo�o Rat�o comeu a D. Carochinha./,
	   q/O Eng. visitou a av. do Marqu�s./,
	   q/O Ex. Sr. Ant�nio foi prof. de Matem�tica./,
	   q/O Pe. Joaquim casou o Arq. Jo�o com a Prof�. Joana./,
	   q/Os profs. v�o ao lg. do Pa�o./,
	   q/Os profs. v�o ao lgo. do Pa�o./,
	   q/As profas. tamb�m v�o ao lgo. do Pa�o./,
	   q/No s�c. V A.C. j� n�o existiam dinossauros./,
	   q/Os Exmos. Srs. deputados que.../,
	   q/Os Exmos. Srs. Drs. v�o almo�ar ao Snack-Bar./,
	   q/Na rua Cel. Ant�nio virar � esquerda, pela avenida do Sen. Joaquim./,
	   q/A empresa de Marco Correia e Cia. Lda. fica na Trv. M�rio Soares./,
	  );

for (@sts) {
  is(trim($ss[$i++]),$_)
}


##------
sub trim {
  my $x = shift;
  $x =~ s/^[\n\s]*//;
  $x =~ s![\n\s]*$!!;
  $x
}
