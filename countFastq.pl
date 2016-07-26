#!/usr/bin/perl
#

&help if (@ARGV != 1);

$num = 0;
open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  $num ++;
}
close IN;

$num /= 4;
print STDOUT "$num\n";

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: countFastq.pl fastq\n";
  exit(-1);
}
