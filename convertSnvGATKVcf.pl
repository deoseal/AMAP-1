#!/usr/bin/perl
#

&help if (@ARGV != 1);

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^#/) {
    print STDOUT "$line\n";
  } else {
    @element = split(/\t/,$line);
    next if (($element[0] eq "Mt") || ($element[0] eq "Pt"));
    if ($element[6] =~ /PASS/) {
      $element[6] = "Not_Filtered";
      $num1 ++;
    } else {
      $element[6] = "Filtered";
      $num2 ++;
    }
    print STDOUT "$element[0]";
    for($i=1; $i<@element; $i++) {
      print STDOUT "\t$element[$i]";
    }
    print STDOUT "\n";
  }
}
close IN;

print STDERR "$num1\t$num2\n";

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: convertSnvGatkVcf.pl vcf\n";
  exit(-1);
}
