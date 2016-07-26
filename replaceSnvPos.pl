#!/usr/bin/perl
#

&help if (@ARGV != 2);

open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^#/);
  @element = split(/\t/,$line);
  $key = $element[2];
  $vcf_pos{$key} = $element[1];
}
close IN;

open(IN,"<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^#/) {
    print STDOUT "$line\n";
    next;
  }

  @element = split(/\t/,$line);
  $key = $element[23];

  print STDOUT "$element[0]\t$vcf_pos{$key}";
  for($i=2; $i<@element; $i++) {
    print STDOUT "\t$element[$i]";
  }
  print STDOUT "\n";
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: replaceSnvPos.pl read.snv.ann2.vcf read.snv.ann2.txt\n";
  exit(-1);
}
