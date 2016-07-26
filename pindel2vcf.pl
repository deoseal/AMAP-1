#!/usr/bin/perl
#

&help if (@ARGV != 1);

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line !~ /BP_range/);
  @element = split(/\s+/,$line);

  $sv_size = $element[2];
  $chr = $element[7];
  $pos1 = $element[9];
  $pos2 = $element[10];

  next if ($chr eq "Mt");
  next if ($chr eq "Pt");
  next if ($sv_size < 10);

  print STDOUT "$chr\t$pos1\t.\t.\t.\t.\t.\t.\t.\n";
  print STDOUT "$chr\t$pos2\t.\t.\t.\t.\t.\t.\t.\n";
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: pindel2vcf.pl pindel.output\n";
  exit(-1);
}
