#!/usr/bin/perl
#

&help if (@ARGV != 1);

$num = 0;

open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^#/) {
    print STDOUT "$line\n";
  } else {
    $num ++;
    $id = sprintf("ID%d",$num);
    @element = split(/\t/,$line);
    if ($element[2] eq ".") {
      $element[2] = "None:$id";
    } else {
      $element[2] .= ":$id";
    }
    print STDOUT $element[0];
    for($i=1; $i<@element; $i++) {
      print STDOUT "\t$element[$i]";
    }
    print STDOUT "\n";
  }
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: addId.pl read-0.snv.snp.vcf\n";
  exit(-1);
}
