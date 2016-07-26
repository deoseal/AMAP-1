#!/usr/bin/perl
#

&help if (@ARGV != 1);

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\t/,$line);
  print STDOUT "$element[1]\n";
}
close IN;

print STDOUT "exit\n";

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: cnv2region.pl cnv\n";
  exit(-1);
}
