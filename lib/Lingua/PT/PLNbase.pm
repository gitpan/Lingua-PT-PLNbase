package Lingua::PT::PLNbase;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Lingua::PT::Abbrev;

require Exporter;
our @ISA = qw(Exporter);

use locale;


our @EXPORT = qw(atomiza frases separa_frases fsentences tokeniza has_accents remove_accents);
our $VERSION = '0.13';

our $abrev;

our $protect = '
       \#n\d+
    |  \w+\'\w+
    |  [\w_.-]+ \@ [\w_.-]+\w                    # emails
    |  \w+\.[��]                                 # ordinals
    |  <[^>]*>                                   # markup XML SGML
    |  \d+(?:\.\d+)+                             # numbers
    |  \d+\:\d+                                  # the time
    |  ((https?|ftp|gopher)://|www)[\w_./~-]+\w  # urls
    |  \w+(-\w+)+                                # d�-lo-�
';


our ($savit_n,%savit_p);
our %conf;


sub import {
  my $class = shift;
  our %conf = @_;
  $class->export_to_level(1, undef, @EXPORT);

  if ($conf{abbrev} && -f $conf{abbrev}) {
    $conf{ABBREV} = Lingua::PT::Abbrev->new($conf{abbrev});
  } else {
    $conf{ABBREV} = Lingua::PT::Abbrev->new();
  }

  $abrev = $conf{ABBREV}->regexp(nodot=>1);
}




sub _savit{
  my $a=shift;
  $savit_p{++$savit_n}=$a ;
  " __MARCA__$savit_n "
}

sub _loadit{
  my $a = shift;
  $a =~ s/ ?__MARCA__(\d+) ?/$savit_p{$1}/g;
  $savit_n = 0;
  $a;
}


sub atomiza {
  return _tokenize(@_);
}

sub _tokenize{
  my $conf = {};
  my $result = "";
  my $text = shift;

  if (ref($text) eq "HASH") {
    $conf = { %$conf, %$text };
    $text = shift;
  }

  local $/ = ">";
  my %tag=();
  my ($a,$b);
  for ($text) {
    if(/<(\w+)(.*?)>/) {
      ($a, $b) = ($1,$2);
      if ($b =~ /=/ )  { $tag{'v'}{$a}++ }
      else             { $tag{'s'}{$a}++ }
    }
    s/<\?xml.*?\?>//s;
    s/($protect)/_savit($1)/xge;
    s!\b((([A-Z])\.)+)!       _savit($1)!gie;


    s!([\�\]])!$1 !g;
    s#([\�\[])# $1#g;

    # No tokenizer de Oslo usa-se � e � para distinguir entre abrir e fechar...
    # Para isso...
    # separa as aspas anteriores
    s/ \"/ \� /g;
    # separa as aspas posteriores
    s/\"([ .?!:;,]?)/ \� $1/g;
    # separa as aspas posteriores mesmo no fim
    s/\"$/ \�/g;

    s/(\s*\b\s*|\s+)/\n/g;

    # s#\"# \" #g;
    # s/(.)\n-\n/$1-/g;
    s/\n+/\n/g;
    s/\n(\.?[��])\b/$1/g;
    while ( s#\b([0-9]+)\n([\,.])\n([0-9]+\n)#$1$2$3#g ){};
    s#\n($abrev)\n\.\n#\n$1\.\n#ig;


    s#([\]\)])([.,;:!?])#$1\n$2#g;

    s/\n*</\n</;
    $_=_loadit($_);
    s/(\s*\n)+$/\n/;
    s/^(\s*\n)+//;
    $result.=$_;
  }

  $result =~ s/\n$//g;


  if (wantarray) {
    return split /\s+/, $result
  } else {
    $result =~ s/\n/$conf->{rs}/g if defined $conf->{rs};
    return $result;
  }
}


sub tokeniza {
  my $par = shift;

  for ($par) {
    s/([!?]+)/ $1/g;
    s/([.,;\��])/ $1/g;

    # separa os dois pontos s� se n�o entre n�meros 9:30...
    s/:([^0-9])/ :$1/g;

    # separa os dois pontos s� se n�o entre n�meros e n�o for http:/...
    s/([^0-9]):([^\/])/$1 :$2/g;

    # was s/([�`])/$1 /g; -- mas tava a dar problemas com o emacs :|
    s!([`])!$1 !g;

    # s� separa o par�ntesis esquerdo quando n�o engloba n�meros ou asterisco
    s/\(([^1-9*])/\( $1/g;

    # s� separa o par�ntesis direito quando n�o engloba n�meros ou asterisco ou percentagem
    s/([^0-9*%])\)/$1 \)/g;

    # desfaz a separa��o dos par�nteses para B)
    s/> *([A-Za-z]) \)/> $1\)/g;

    # desfaz a separa��o dos par�nteses para (a)
    s/> *\( ([a-z]) \)/> \($1\)/g;

    # separa��o dos par�nteses para ( A4 )
    s/(\( +[A-Z]+[0-9]+)\)/ $1 \)/g;

    # separa o par�ntesis recto esquerdo desde que n�o [..
    s/\[([^.�])/[ $1/g;

    # separa o par�ntesis recto direito desde que n�o ..]
    s/([^.�])\]/$1 ]/g;

    # separa as retic�ncias s� se n�o dentro de [...]
    s/([^[])�/$1 �/g;

    # desfaz a separa��o dos http:
    s/http :/http:/g;

    # separa as aspas anteriores
    s/ \"/ \� /g;

    # separa as aspas anteriores mesmo no inicio
    s/^\"/ \� /g;

    # separa as aspas posteriores
    s/\" / \� /g;

    # separa as aspas posteriores mesmo no fim
    s/\"$/ \�/g;

    # trata dos ap�strofes
    # trata do ap�strofe: s� separa se for pelica
    s/([^dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # trata do ap�strofe: s� separa se for pelica
    s/(\S[dDlL])\'([\s\',:.?!])/$1 \'$2/g;
    # separa d' do resto da palavra "d'amor"... "dest'�poca"
    s/([A-Z������������a-z������������])\'([A-Z������������a-z������������])/$1\' $2/;

    #Para repor PME's
    s/(\s[A-Z]+)\' s([\s,:.?!])/$1\'s$2/g;

    # isto � para o caso dos ap�strofos n�o terem sido tratados pelo COMPARA
    # separa um ap�strofe final usado como inicial
    s/ '([A-Za-z��������])/ ' $1/g;
    # separa um ap�strofe final usado como inicial
    s/^'([A-Za-z��������])/' $1/g;

    # isto � para o caso dos ap�strofes (plicas) serem os do COMPARA
    s/\`([^ ])/\` $1/g;
    s/([^ ])�/$1 �/g;

    # trata dos (1) ou 1)
    # separa casos como Rocha(1) para Rocha (1)
    s/([a-z����])\(([0-9])/$1 \($2/g;
    # separa casos como dupla finalidade:1)
    s/:([0-9]\))/ : $1/g;

    # trata dos h�fenes
    # separa casos como (It�lia)-Juventus para It�lia) -
    s/\)\-([A-Z])/\) - $1/g;
    # separa casos como 1-universidade
    s/([0-9]\-)([^0-9\s])/$1 $2/g;
  }

  #trata das barras
  #se houver palavras que nao sao todas em maiusculas, separa
  my @barras = ($par=~m%(?:[a-z]+/)+(?:[A-Za-z][a-z]*)%g);
  my $exp_antiga;
  foreach my $exp_com_barras (@barras) {
    if (($exp_com_barras !~ /[a-z]+a\/o$/) and # Ambicioso/a
        ($exp_com_barras !~ /[a-z]+o\/a$/) and # cozinheira/o
        ($exp_com_barras !~ /[a-z]+r\/a$/)) { # desenhador/a
             $exp_antiga=$exp_com_barras;
             $exp_com_barras=~s#/# / #g;
             $par=~s/$exp_antiga/$exp_com_barras/g;
	   }
  }

  for ($par) {
    s# e / ou # e/ou #g;
    s#([Kk])m / h#$1m/h#g;
    s# mg / kg# mg/kg#g;
    s#r / c#r/c#g;
    s#m / f#m/f#g;
    s#f / m#f/m#g;
  }


  if (wantarray) {
    return split /\s+/, $par
  } else {
    $par =~ s/\s+/\n/g;
    return $par
  }
}




sub frases { _sentences(@_) }
sub _sentences{
  my $terminador='([.?!;]+[�]?|<[pP]\b.*?>|<br>|\n\n+|:[\s\n](?=[-�"][A-Z]))';

  my @r;
  my $MARCA = "\0x01";
  my $par = shift;
  for ($par) {
    s!($protect)!          _savit($1)!xge;
    s!\b(($abrev)\.)!      _savit($1)!ige;
    s!\b(\w+(�|�)\.)!      _savit($1)!ige;
    s!\b(([A-Z])\.)!       _savit($1)!gie;  # este � parte para n�o apanhar min�lculas (s///i)
    s!($terminador)!$1$MARCA!g;
    $_ = _loadit($_);
    @r = split(/$MARCA/,$_);
  }
  if (@r && $r[-1] =~ /^\s*$/s) {
    pop(@r)
  }
  return map { _trim($_) } @r;
}

sub _trim {
  my $x = shift;
  $x =~ s/^[\n\r\s]+//;
  $x =~ s/[\n\r\s]+$//;
  return $x;
}


sub tratar_pontuacao_interna {
  my $par = shift;

  #    print "Estou no pontua��o interna... $par\n";

  for ($par) {
    # proteger o �
    s/�/��/g;

    # tratar das retic�ncias
    s/\.\.\.+/�/g;

    s/\+/\+\+/g;

    # tratar de iniciais seguidas por ponto, eventualmente com
    # par�nteses, no fim de uma frase
    s/([A-Z])\. ([A-Z])\.(\s*[])]*\s*)$/$1+ $2+$3 /g;

    # iniciais com espa�o no meio...
    s/ a\. C\./ a+C+/g;
    s/ d\. C\./ d+C+/g;

    # tratar dos pontos nas abreviaturas
    s/\.�/�+/g;
    s/�\./+�/g;
    s/\.�/+�/g;
    s/�\./�+/g;

    #s� mudar se n�o for amb�guo com ponto final
    s/�\. +([^A-Z��������\�])/�+ $1/g;

    # formas de tratamento
    s/Ex\./Ex+/g; # Ex.
    s/ ex\./ ex+/g; # ex.
    s/Exa(s*)\./Exa$1+/g; # Exa., Exas.
    s/ exa(s*)\./ exa$1+/g; # exa., exas
    s/Pe\./Pe+/g;
    s/Dr(a*)\./Dr$1+/g; # Dr., Dra.
    s/ dr(a*)\./ dr$1+/g; # dr., dra.
    s/ drs\./ drs+/g; # drs.
    s/Eng(a*)\./Eng$1+/g; # Eng., Enga.
    s/ eng(a*)\./ eng$1+/g; # eng., enga.
    s/([Ss])r(t*)a\./$1r$2a+/g; # Sra., sra., Srta., srta.
    s/([Ss])r(s*)\./$1r$2+/g; # Sr., sr., Srs., srs.
    s/ arq\./ arq+/g; # arq.
    s/Prof(s*)\./Prof$1+/g; # Prof., Profs.
    s/Profa(s*)\./Profa$1+/g; # Profa., Profas.
    s/ prof(s*)\./ prof$1+/g; # prof., profs.
    s/ profa(s*)\./ profa$1+/g; # profa., profas.
    s/\. Sen\./+ Sen+/g; # senador (vem sempre depois de Av. ou R. ...)
    s/ua Sen\./ua Sen+/g; # senador (depois [Rr]ua ...)
    s/Cel\./Cel+/g; # coronel
    s/ d\. / d+ /g; # d. Luciano

    # partes de nomes (pospostos)
    s/ ([lL])da\./ $1da+/g; # limitada
    s/ cia\./ cia+/g; # companhia
    s/Cia\./Cia+/g; # companhia
    s/Jr\./Jr+/g;

    # moradas
    s/Av\./Av+/g;
    s/ av\./ av+/g;
    s/Est(r*)\./Est$1+/g;
    s/Lg(o*)\./Lg$1+/g;
    s/ lg(o*)\./ lg$1+/g;
    s/T(ra)*v\./T$1v+/g; # Trav., Tv.
    s/([^N])Pq\./$1Pq+/g; # Parque (cuidado com CNPq)
    s/ pq\./ pq+/g; # parque
    s/Jd\./Jd+/g; # jardim
    s/Ft\./Ft+/g; # forte
    s/Cj\./Cj+/g; # conjunto
    s/ ([lc])j\./ $1j+/g; # conjunto ou loja
    #    $par=~s/ al\./ al+/g; # alameda tem que ir para depois de et.al...

    # Remover aqui uns warningzitos
    s/Tel\./Tel+/g; # Tel.
    s/Tel(e[fm])\./Tel$1+/g; #  Telef., Telem.
    s/ tel\./ tel+/g; # tel.
    s/ tel(e[fm])\./ tel$1+/g; #  telef., telem.
    s/Fax\./Fax+/g; # Fax.
    s/ cx\./ cx+/g; # caixa

    # abreviaturas greco-latinas
    s/ a\.C\./ a+C+/g;
    s/ a\.c\./ a+c+/g;
    s/ d\.C\./ d+C+/g;
    s/ d\.c\./ d+c+/g;
    s/ ca\./ ca+/g;
    s/etc\.([.,;])/etc+$1/g;
    s/etc\.\)([.,;])/etc+)$1/g;
    s/etc\. --( *[a-z��������,])/etc+ --$1/g;
    s/etc\.(\)*) ([^A-Z�������])/etc+$1 $2/g;
    s/ et\. *al\./ et+al+/g;
    s/ al\./ al+/g; # alameda
    s/ q\.b\./ q+b+/g;
    s/ i\.e\./ i+e+/g;
    s/ibid\./ibid+/g;
    s/ id\./ id+/g; # se calhar � preciso ver se n�o vem sempre precedido de um (
    s/op\.( )*cit\./op+$1cit+/g;
    s/P\.S\./P+S+/g;

    # unidades de medida
    s/([0-9][hm])\. ([^A-Z��������])/$1+ $2/g; # 19h., 24m.
    s/([0-9][km]m)\. ([^A-Z��������])/$1+ $2/g; # 20km., 24mm.
    s/([0-9]kms)\. ([^A-Z��������])/$1+ $2/g; # kms. !!
    s/(\bm)\./$1+/g; # metros no MINHO

    # outros
    s/\(([Oo]rgs*)\.\)/($1+)/g; # (orgs.)
    s/\(([Ee]ds*)\.\)/($1+)/g; # (eds.)
    s/s�c\./s�c+/g;
    s/p�g(s*)\./p�g$1+/g;
    s/pg\./pg+/g;
    s/pag\./pag+/g;
    s/ ed\./ ed+/g;
    s/Ed\./Ed+/g;
    s/ s�b\./ s�b+/g;
    s/ dom\./ dom+/g;
    s/ id\./ id+/g;
    s/ min\./ min+/g;
    s/ n\.o(s*) / n+o$1 /g; # abreviatura de numero no MLCC-DEB
    s/ ([Nn])o\.(s*)\s*([0-9])/ $1o+$2 $3/g; # abreviatura de numero no., No.
    s/ n\.(s*)\s*([0-9])/ n+$1 $2/g; # abreviatura de numero n. no ANCIB
    s/ num\. *([0-9])/ num+ $1/g; # abreviatura de numero num. no ANCIB
    s/ c\. ([0-9])/ c+ $1/g; # c. 1830
    s/ p\.ex\./ p+ex+/g;
    s/ p\./ p+/g;
    s/ pp\./ pp+/g;
    s/ art(s*)\./ art$1+/g;
    s/Min\./Min+/g;
    s/Inst\./Inst+/g;
    s/vol(s*)\./vol$1+ /g;
    s/ v\. *([0-9])/ v+ $1/g; # abreviatura de volume no ANCIB
    s/\(v\. *([0-9])/\(v+ $1/g; # abreviatura de volume no ANCIB
    s/^v\. *([0-9])/v+ $1/g; # abreviatura de volume no ANCIB
    s/Obs\./Obs+/g;

    # Abreviaturas de meses
    s/(\W)jan\./$1jan+/g;
    s/\Wfev\./$1fev+/g;
    s/(\/\s*)mar\.(\s*[0-9\/])/$1mar+$2/g; # a palavra "mar"
    s/(\W)mar\.(\s*[0-9]+)/$1mar\+$2/g;
    s/(\W)abr\./$1abr+/g;
    s/(\W)mai\./$1mai+/g;
    s/(\W)jun\./$1jun+/g;
    s/(\W)jul\./$1jul+/g;
    s/(\/\s*)ago\.(\s*[0-9\/])/$1ago+$2/g; # a palavra inglesa "ago"
    s/ ago\.(\s*[0-9\/])/ ago+$1/g; # a palavra inglesa "ago./"
    s/(\W)set\.(\s*[0-9\/])/$1set+$2/g; # a palavra inglesa "set"
    s/([ \/])out\.(\s*[0-9\/])/$1out+$2/g; # a palavra inglesa "out"
    s/(\W)nov\./$1nov+/g;
    s/(\/\s*)dez\.(\s*[0-9\/])/$1dez+$2/g; # a palavra "dez"
    s/(\/\s*)dez\./$1dez+/g; # a palavra "/dez."

    # Abreviaturas inglesas
    s/Bros\./Bros+/g;
    s/Co\. /Co+ /g;
    s/Co\.$/Co+/g;
    s/Com\. /Com+ /g;
    s/Com\.$/Com+/g;
    s/Corp\. /Corp+ /g;
    s/Inc\. /Inc+ /g;
    s/Ltd\. /Ltd+ /g;
    s/([Mm])r(s*)\. /$1r$2+ /g;
    s/Ph\.D\./Ph+D+/g;
    s/St\. /St+ /g;
    s/ st\. / st+ /g;

    # Abreviaturas francesas
    s/Mme\./Mme+/g;

    # Abreviaturas especiais do Di�rio do Minho
    s/ habilit\./ habilit+/g;
    s/Hab\./Hab+/g;
    s/Mot\./Mot+/g;
    s/\-Ang\./-Ang+/g;
    s/(\bSp)\./$1+/g; # Sporting
    s/(\bUn)\./$1+/g; # Universidade

    # Abreviaturas especiais do Folha
    s/([^'])Or\./$1Or+/g; # alemanha Oriental, evitar d'Or
    s/Oc\./Oc+/g; # alemanha Ocidental

  }

  # tratar dos conjuntos de iniciais
  my @siglas_iniciais = ($par =~ /^(?:[A-Z]\. *)+[A-Z]\./);
  my @siglas_finais   = ($par =~ /(?:[A-Z]\. *)+[A-Z]\.$/);
  my @siglas = ($par =~ m#(?:[A-Z]\. *)+(?:[A-Z]\.)(?=[]\)\s,;:!?/])#g); #trata de conjuntos de iniciais
  push (@siglas, @siglas_iniciais);
  push (@siglas, @siglas_finais);
  my $sigla_antiga;
  foreach my $sigla (@siglas) {
    $sigla_antiga = $sigla;
    $sigla =~ s/\./+/g;
    $sigla_antiga =~ s/\./\\\./g;
    #	print "SIGLA antes: $sigla, $sigla_antiga\n";
    $par =~ s/$sigla_antiga/$sigla/g;
    #	print "SIGLA: $sigla\n";
  }

  # tratar de pares de iniciais ligadas por h�fen (� francesa: A.-F.)
  for ($par) {
    s/ ([A-Z])\.\-([A-Z])\. / $1+-$2+ /g;
    # tratar de iniciais (�nicas?) seguidas por ponto
    s/ ([A-Z])\. / $1+ /g;
    # tratar de iniciais seguidas por ponto
    s/^([A-Z])\. /$1+ /g;
    # tratar de iniciais seguidas por ponto antes de aspas "D. Jo�o
    # VI: Um Rei Aclamado"
    s/([("\�])([A-Z])\. /$1$2+ /g;
  }

  # Tratar dos URLs (e tamb�m dos endere�os de email)
  # email= url@url...
  # aceito endere�os seguidos de /hgdha/hdga.html
  #  seguidos de /~hgdha/hdga.html
  #    @urls=($par=~/(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9-]+)*?(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\/[a-z.]+\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);

  my @urls = ($par =~ /(?:[a-z][a-z0-9-]*\.)+(?:[a-z]+)(?:\/~*[a-z0-9][a-z0-9.-]+)*(?:\?[a-z]+=[a-z0-9-]+(?:\&[a-z]+=[a-z0-9-]+)*)*/gi);
  my $url_antigo;
  foreach my $url (@urls) {
    $url_antigo = $url;
    $url_antigo =~ s/\./\\./g; # para impedir a substitui��o de P.o em vez de P\.o
    $url_antigo =~ s/\?/\\?/g;
    $url =~ s/\./+/g;
    # Se o �ltimo ponto est� mesmo no fim, n�o faz parte do URL
    $url =~ s/\+$/./;
    $url =~ s/\//\/\/\/\//g; # p�e quatro ////
    $par =~ s/$url_antigo/$url/;
  }
  # print "Depois de tratar dos URLs: $par\n";

  for ($par) {
    # de qualquer maneira, se for um ponto seguido de uma v�rgula, �
    # abreviatura...
    s/\. *,/+,/g;
    # de qualquer maneira, se for um ponto seguido de outro ponto, �
    # abreviatura...
    s/\. *\./+./g;

    # tratamento de numerais
    s/([0-9]+)\.([0-9]+)\.([0-9]+)/$1_$2_$3/g;
    s/([0-9]+)\.([0-9]+)/$1_$2/g;

    # tratamento de numerais cardinais
    # - tratar dos n�meros com ponto no in�cio da frase
    s/^([0-9]+)\. /$1+ /g;
    # - tratar dos n�meros com ponto antes de min�sculas
    s/([0-9]+)\. ([a-z��������])/$1+ $2/g;

    # tratamento de numerais ordinais acabados em .o
    s/([0-9]+)\.([oa]s*) /$1+$2 /g;
    # ou expressos como 9a.
    s/([0-9]+)([oa]s*)\. /$1$2+ /g;

    # tratar numeracao decimal em portugues
    s/([0-9]),([0-9])/$1#$2/g;

    #print "TRATA: $par\n";

    # tratar indica��o de horas
    #   esta � tratada na tokeniza��o - n�o separando 9:20 em 9 :20
  }
  return $par;
}


sub separa_frases {
  my $par = shift;

  # $num++;

  $par = &tratar_pontuacao_interna($par);

  #  print "Depois de tratar_pontuacao_interna: $par\n";

  for ($par) {

    # primeiro junto os ) e os -- ao caracter anterior de pontua��o
    s/([?!.])\s+\)/$1\)/g; # p�r  "ola? )" para "ola?)"
    s/([?!.])\s+\-/$1-/g; # p�r  "ola? --" para "ola?--"
    s/([?!.])\s+�/$1�/g; # p�r  "ola? ..." para "ola?..."
    s/�\s+\-/$1-/g; # p�r  "ola� --" para "ola�--"

    # junto tb o travess�o -- `a pelica '
    s/\-\- \' *$/\-\-\' /;

    # separar esta pontua��o, apenas se n�o for dentro de aspas, ou
    # seguida por v�rgulas ou par�nteses o a-z est�o l� para n�o
    # separar /asp?id=por ...
    s/([?!]+)([^-\�'�,�?!)"a-z])/$1.$2/g;

    # Deixa-se o travess�o para depois
    # print "Depois de tratar do ?!: $par";

    # separar as retic�ncias entre par�nteses apenas se forem seguidas
    # de nova frase, e se n�o come�arem uma frase elas pr�prias
    s/([\w?!])�([\�"�']*\)) *([A-Z������])/$1�$2.$3/g;

    # print "Depois de tratar das retic. seguidas de ): $par";

    # separar os pontos antes de par�nteses se forem seguidos de nova
    # frase
    s/([\w])\.([)]) *([A-Z������])/$1 + $2.$3/g;

    # separar os pontos ? e ! antes de par�nteses se forem seguidos de
    # nova frase, possivelmente tb iniciada por abre par�nteses ou
    # travess�o
    s/(\w[?!]+)([)]) *((?:\( |\-\- )*[A-Z������])/$1 $2.$3/g;

    # separar as retic�ncias apenas se forem seguidas de nova frase, e
    # se n�o come�arem uma frase elas pr�prias trata tamb�m das
    # retic�ncias antes de aspas
    s/([\w\d!?])\s*�(["\�'�]*) ([^\�"'a-z��������,;?!)])/$1�$2.$3/g;
    s/([\w\d!?])\s*�(["\�'�]*)\s*$/$1�$2. /g;

    # aqui trata das frases acabadas por aspas, eventualmente tb
    # fechando par�nteses e seguidas por retic�ncias
    s/([\w!?]["\�'�])�(\)*) ([^\�"a-z��������,;?!)])/$1�$2.$3/g;

    #print "depois de tratar das reticencias seguidas de nova frase: $par\n";

    # tratar dos dois pontos: apenas se seguido por discurso directo
    # em mai�sculas
    s/: \�([A-Z������])/:.\�$1/g;
    s/: (\-\-[ \�]*[A-Z������])/:.$1/g;

    # tratar dos dois pontos se eles acabam o par�grafo (� preciso p�r
    # um espa�o)
    s/:\s*$/:. /;

    # tratar dos pontos antes de aspas
    s/\.(["\�'�])([^.])/+$1.$2/g;

    # tratar das aspas quando seguidas de novas aspas
    s/\�\s*[\�"]/\�. \�/g;

    # tratar de ? e ! seguidos de aspas quando seguidos de mai�scula
    # eventualmente iniciados por abre par�nteses ou por travess�o
    s/([?!])([\�"'�]) ((?:\( |\-\- )*[A-Z��������])/$1$2. $3/g;

    # separar os pontos ? e ! antes de par�nteses e possivelmente
    # aspas se forem o fim do par�grafo
    s/(\w[?!]+)([)][\�"'�]*) *$/$1 $2./;

    # tratar dos pontos antes de aspas precisamente no fim
    s/\.([\�"'�])\s*$/+$1. /g;

    # tratar das retic�ncias e outra pontua��o antes de aspas ou
    # plicas precisamente no fim
    s/([!?�])([\�"'�]+)\s*$/$1$2. /g;

    #tratar das retic�ncias precisamente no fim
    s/�\s*$/�. /g;

    # tratar dos pontos antes de par�ntesis precisamente no fim
    s/\.\)\s*$/+\). /g;

    # aqui troco .) por .). ...
    s/\.\)\s/+\). /g;
  }

  # tratar de par�grafos que acabam em letras, n�meros, v�rgula ou
  # "-", chamando-os fragmentos #ALTERACAO
  my $fragmento;
  if ($par =~/[A-Za-z�������������0-9\),-][\�\"\'�>]*\s*\)*\s*$/) {
    $fragmento = 1
  }

  for ($par) {
    # se o par�grafo acaba em "+", deve-se juntar "." outra vez.
    s/([^+])\+\s*$/$1+. /;

    # se o par�grafo acaba em abreviatura (+) seguido de aspas ou par�ntesis, deve-se juntar "."
    s/([^+])\+\s*(["\�'�\)])\s*$/$1+$2. /;

    # print "Par�grafo antes da separa��o: $par";
  }

  my @sentences = split /\./,$par;
  if (($#sentences > 0) and not $fragmento) {
    pop(@sentences);
  }

  my $resultado = "";
  # para saber em que frase p�r <s frag>
  my $num_frase_no_paragrafo = 0;
  foreach my $frase (@sentences) {
    $frase = &recupera_ortografia_certa($frase);

    if (($frase=~/[.?!:;][\�"'�]*\s*$/) or
	($frase=~/[.?!] *\)[\�"'�]*$/)) {
      # frase normal acabada por pontua��o
      $resultado .= "<s> $frase </s>\n";
    }

    elsif (($fragmento) and ($num_frase_no_paragrafo == $#sentences)) {
      $resultado .= "<s frag> $frase </s>\n";
      $fragmento = 0;
    }
    else {
      $resultado .= "<s> $frase . </s>\n";
    }
    $num_frase_no_paragrafo++;
  }

  return $resultado;
}


sub recupera_ortografia_certa {
  # os sinais literais de + s�o codificados como "++" para evitar
  # transforma��o no ponto, que � o significado do "+"

  my $par = shift;

  for ($par) {
    s/([^+])\+(?!\+)/$1./g; # um + n�o seguido por +
    s/\+\+/+/g;
    s/^�(?!�)/.../g; # se as retic�ncias come�am a frase
    s/([^�(])�(?!�)\)/$1... \)/g; # porque se juntou no separa_frases 
    # So nao se faz se for (...) ...
    s/([^�])�(?!�)/$1.../g; # um � n�o seguido por �
    s/��/�/g;
    s/_/./g;
    s/#/,/g;
    s#////#/#g; #passa 4 para 1
    s/([?!])\-/$1 \-/g; # porque se juntou no separa_frases
    s/([?!])\)/$1 \)/g; # porque se juntou no separa_frases 
  }
  return $par;
}



































sub fsentences {
  my %opts = (
	      o_format => 'XML',
	      s_tag    => 's',
	      s_num    => '1',
	      s_last   => '',

	      p_tag    => 'p',
	      p_num    => '1',
	      p_last   => '',

	      t_tag    => 'text',
	      t_num    => 'f',
	      t_last   => '',

	      tokenize => 0,

	      output   => \*STDOUT,
	      input_p_sep => '',
	     );

  %opts = (%opts, %{shift()}) if ref($_[0]) eq "HASH";


  my @files = @_;
  @files = (\*STDIN) unless @files;

  my $oldselect;
  if (!ref($opts{output})) {
    open OUT, ">$opts{output}" or die("Cannot open file for writting: $!\n");
    $oldselect = select OUT;
  }

  for my $file (@files) {
    my $fh;
    if (ref($file)) {
      $fh = $file;
    } else {
      open $fh, $file or die("Cannot open file $file:$!\n");
      print _open_t_tag(\%opts, $file);
    }

    my $par;
    local $/ = $opts{input_p_sep};
    while ($par = <$fh>) {
      print _open_p_tag(\%opts);

      chomp($par);

      for my $s (_sentences($par)) {
	print _open_s_tag(\%opts), _clean(\%opts,$s), _close_s_tag(\%opts);
      }

      print _close_p_tag(\%opts);
    }


    unless (ref($file)) {
      print _close_t_tag(\%opts);
      close $fh
    }

  }

  if (!ref($opts{output})) {
    select $oldselect;
  }

}

sub _clean {
  my $opts = shift;
  my $str = shift;

  if ($opts->{tokenize}) {
    $str = join(" ", atomiza($str))
  } else {
    $str =~ s/\s+/ /g;
  }
  return $str;
}

sub _open_t_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{t_tag}) {
    if ($opts->{t_num} eq 0) {
      return "<$opts->{t_tag}>\n";
    } elsif ($opts->{t_num} eq 'f') {
      $opts->{t_last} = $file;
      $opts->{p_last} = 0;
      $opts->{s_last} = 0;
      return "<$opts->{t_tag} file=\"$file\">\n";
    } else {
      ## t_num = 1 :-)
      ++$opts->{t_last};
      $opts->{p_last} = 0;
      $opts->{s_last} = 0;
      return "<$opts->{t_tag} id=\"$opts->{t_last}\">\n";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_t_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{t_tag}) {
    return "</$opts->{t_tag}>\n";
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _open_p_tag {
  my $opts = shift;

  if ($opts->{o_format} eq "XML" &&
      $opts->{p_tag}) {
    if ($opts->{p_num} == 0) {
      return "<$opts->{p_tag}>\n";
    } elsif ($opts->{p_num} == 1) {
      ++$opts->{p_last};
      $opts->{s_last} = 0;
      return "<$opts->{p_tag} id=\"$opts->{p_last}\">\n";
    } else {
      ## p_num = 2
      ++$opts->{p_last};
      $opts->{s_last} = 0;
      return "<$opts->{p_tag} id=\"$opts->{t_last}.$opts->{p_last}\">\n";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_p_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{p_tag}) {
    return "</$opts->{p_tag}>\n";
  }
  return "" if ($opts->{o_format} eq "NATools");
}


sub _open_s_tag {
  my $opts = shift;

  if ($opts->{o_format} eq "XML" &&
      $opts->{s_tag}) {
    if ($opts->{s_num} == 0) {
      return "<$opts->{s_tag}>";
    } elsif ($opts->{s_num} == 1) {
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{s_last}\">";

    } elsif ($opts->{s_num} == 2) {
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{p_last}.$opts->{s_last}\">";

    } else {
      ## p_num = 3
      ++$opts->{s_last};
      return "<$opts->{s_tag} id=\"$opts->{t_last}.$opts->{p_last}.$opts->{s_last}\">";
    }
  }
  return "" if ($opts->{o_format} eq "NATools");
}

sub _close_s_tag {
  my $opts = shift;
  my $file = shift || "";
  if ($opts->{o_format} eq "XML" &&
      $opts->{s_tag}) {
    return "</$opts->{s_tag}>\n";
  }
  return "\n\$\n" if ($opts->{o_format} eq "NATools");
}


sub has_accents {
  my $word = shift;
  if ($word =~ m![�����������������������]!i) {
    return 1
  } else {
    return 0
  }
}

sub remove_accents {
  my $word = shift;
  $word =~ tr/�����������������������/caeiouaeiouaoaeiouaeiou/;
  $word =~ tr/�����������������������/CAEIOUAEIOUAOAEIOUAEIOU/;
  return $word;
}


1;
__END__

=head1 NAME

Lingua::PT::PLNbase - Perl extension for NLP of the Portuguese

=head1 SYNOPSIS

  use Lingua::PT::PLNbase;

  my @atomos = atomiza($texto);
  my $atomos_um_por_linha = atomiza($texto);

  my @frases = frases($texto);
  my $frases = separa_frases($texto);


=head1 DESCRIPTION

=head2 Atomiza��o

Este m�dulo inclui um m�todo configur�vel para a atomiza��o de corpus
na l�ngua portuguesa. No entanto, � poss�vel que possa ser usado para
outras l�nguas.

A forma simples de uso do atomizador � usando directamente a fun��o
C<atomiza> que retorna um texto em que cada linha cont�m um �tomo, ou o
uso da fun��o C<tokeniza> que cont�m outra vers�o de atomizador.

=over 4

=item atomiza

Usa um algor�tmo desenvolvido no Projecto Natura

=item tokeniza

Usa um algor�tmo desenvolvido no P�lo de Oslo da Linguateca

=back

=head2 Segmenta��o

Este m�dulo � uma extens�o Perl para a segmenta��o de textos em
linguagem natural. O objectivo principal ser� a possibilidade de
segmenta��o a v�rios n�veis, no entanto esta primeira vers�o permite
apenas a separa��o em frases (frasea��o) usando uma de duas variantes:

=over 4

=item frases

  @frases = frases($texto);

Esta � a implementa��o do Projecto Natura, que retorna uma lista de
frases.

=item separa_frases

  $frases = separa_frases($texto);

Esta � a implementa��o da Linguateca, que retorna um texto com uma
frase por linha.

=back

Estas duas implementa��es ir�o ser testadas e aglomeradas numa �nica
que permita ambas as funcionalidades.

=head2 Segmenta��o a v�rios n�veis

=over 4

=item fsentences

A fun��o C<fsentences> permite segmentar um conjunto de ficheiros a
v�rios n�veis: por ficheiro, por par�grafo ou por frase. O output pode
ser realizado em v�rios formatos e obtendo, ou n�o, numera��o de
segmentos.

Esta fun��o � invocada com uma refer�ncia para um hash de configura��o
e uma lista de ficheiros a processar (no caso de a lista ser vazia,
ir� usar o C<STDIN>).

O resultado do processamento � enviado para o C<STDOUT> a n�o ser que
a chave C<output> do hash de configura��o esteja definida. Nesse caso,
o seu valor ser� usado como ficheiro de resultado.

A chave C<input_p_sep> permite definir o separador de par�grafos. Por
omiss�o, � usada uma linha em branco.

A chave C<o_format> define as pol�ticas de etiqueta��o do
resultado. De momento, a �nica pol�tica dispon�vel � a C<XML>.

As chaves C<s_tag>, C<p_tag> e C<t_tag> definem as etiquetas a usar,
na pol�tica XML, para etiquetar frases, par�grafos e textos
(ficheiros), respectivamente. Por omiss�o, as etiquetas usadas s�o
C<s>, C<p> e C<text>.

� poss�vel numerar as etiquetas, definindo as chaves C<s_num>,
C<p_num> ou C<t_num> da seguinte forma:

=over 4

=item '0'

Nenhuma numera��o.

=item 'f'

S� pode ser usado com o C<t_tag>, e define que as etiquetas que
delimitam ficheiros usar� o nome do ficheiro como identificador.

=item '1'

Numera��o a um n�vel. Cada etiqueta ter� um contador diferente.

=item '2'

S� pode ser usado com o C<p_tag> ou o C<s_tag> e obriga � numera��o a
dois n�veis (N.N).

=item '3'

S� pode ser usado com o C<s_tag> e obriga � numera��o a tr�s n�veis (N.N.N)

=back

=back

=head2 Acentua��o

=over 4

=item remove_accents

Esta fun��o remove a acentua��o do texto passado como par�metro

=item has_accents

Esta fun��o verifica se o texto passado como par�metro tem caracteres acentuados

=back

=head2 Fun��es auxiliares

=over 4

=item recupera_ortografia_certa

=item tratar_pontuacao_interna

=back

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Alberto Simoes (ambs@di.uminho.pt)

Diana Santos (diana.santos@sintef.no)

Jos� Jo�o Almeida (jj@di.uminho.pt)

Paulo Rocha (paulo.rocha@di.uminho.pt)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2004 by Linguateca (http://www.linguateca.pt)

(EN)
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

(PT)
Esta biblioteca � software de dom�nio p�blico; pode redistribuir e/ou
modificar este m�dulo nos mesmos termos do pr�prio Perl, quer seja a
vers�o 5.8.1 ou, na sua liberdade, qualquer outra vers�o do Perl 5 que
tenha dispon�vel.

=cut



#
# outputto
# inputfrom
# separator-paragraph-input
#
# [DEFAULT] Politica XML --- '<t> <p> <s>' -- 0, Numercao com ou sem reset, N.N, N.N.N
#                                  (0)                (1)         (2)   (3)
#
# nomes das etiquetas (s => 's', p=>'p', t=>'text')
#
# t: 0 - nenhuma
#    1 - numeracao
#    f - filen^H^Hcheiro [DEFAULT]
#
# p: 0 - nenhuma
#    1 - numeracao 1 nivel [DEFAULT]
#    2 - numercao 2 niveis (N.N)
#
# s: 0 - nenhuma
#    1 - numera��o 1 n�vel [DEFAULT]
#    2 - numera��o 2 n�veis (N.N)
#    3 - numera��o 3 n�veis (N.N.N)
#
# Politica NATools
#
# Politica linha em branco
