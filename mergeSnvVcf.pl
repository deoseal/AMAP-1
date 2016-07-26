#!/usr/bin/perl
#

&help if (@ARGV != 2);

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^#/) {
    print STDOUT "$line\n";
  } else {
    @element = split(/\t/,$line);
    next if (($element[0] eq "Mt") || ($element[0] eq "Pt"));
    $element[6] = "Not_Filtered";
    print STDOUT "$element[0]";
    for($i=1; $i<@element; $i++) {
      print STDOUT "\t$element[$i]";
    }
    print STDOUT "\n";
    $num1 ++;
  }
}
close IN;

open(IN, "<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\t/,$line);
  next if (($element[1] eq "Mt") || ($element[1] eq "Pt"));
  $element[7] = "Filtered";
  print STDOUT "$element[1]";
  for($i=2; $i<@element; $i++) {
    print STDOUT "\t$element[$i]";
  }
  print STDOUT "\n";
  $num2 ++;
}
close IN;

print STDERR "$num1\t$num2\n";

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: mergeSnvVcf.pl not_filtered filtered\n";
  exit(-1);
}
