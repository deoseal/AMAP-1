#!/usr/bin/perl
#

&help if (@ARGV != 3);

open(IN, "<$ARGV[2]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^Locus/);
  @element = split(/\t/,$line);
  @ele = split(/:/,$element[0]);
  $depth{$ele[0]}[$ele[1]] = $element[1];
}
close IN;

open(IN, "<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\s+/,$line);
  $copynum{$element[1]} = "$element[3]\t$element[4]";
}
close IN;

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^#/);
  @element = split(/\t/,$line);

  $sv_type = $element[0];
  $posinf = $element[1];
  $sv_size = abs($element[2]);
  @ele = split(/[:-]/,$posinf);
  $chr1 = $ele[0];
  $chr1 =~ s/^chr//;
  $chr2 = $chr1;
  $pos1 = $ele[1];
  $pos2 = $ele[2];

  next if ($chr1 eq "Mt");
  next if ($chr1 eq "Pt");

  $freq{$sv_type} ++;

  $depth_val = ($depth{$chr1}[$pos1] + $depth{$chr2}[$pos2]) / 2;

  $key = "$chr1\t$pos1\t$chr2\t$pos2\t$sv_type";
  $inf{$key} = "$sv_size\t$element[3]\t$element[4]\t$element[5]\t$copynum{$posinf}\t$depth_val";

  $dat{chr} = $chr1;
  $dat{pos} = $pos1;
  $dat{key} = $key;
  push(@keysort,{%dat});
}
close IN;

@keysort = sort{$a->{chr}<=>$b->{chr} || $a->{pos}<=>$b->{pos}} @keysort;

for($i=0; $i<@keysort; $i++) {
  $key = $keysort[$i]{key};
  print STDOUT "$key\t$inf{$key}\n";
}

foreach $key (sort keys %freq) {
  print STDERR "$key\t$freq{$key}\n";
}

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: makeCNVList.pl cnv geno depth\n";
  exit(-1);
}
