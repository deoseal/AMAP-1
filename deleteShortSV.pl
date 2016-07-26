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
    @element = split(/\t/,$line);
    next if ($element[0] eq "Mt");
    next if ($element[0] eq "Pt");
    @element = split(/\;/,$element[7]);
    $svlen = 0;
    for($i=0; $i<@element; $i++) {
      ($item,$val) = split(/\=/,$element[$i]);
      $svlen = abs($val) if ($item eq "SVLEN");
    }
    print STDOUT "$line\n" if ($svlen >= 10);
  }
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: deleteShortSV.pl read-0.snv.snp.vcf\n";
  exit(-1);
}
