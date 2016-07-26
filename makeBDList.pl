#!/usr/bin/perl
#

&help if (@ARGV != 2);

open(IN, "<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^Locus/);
  @element = split(/\t/,$line);
  @ele = split(/:/,$element[0]);
  $depth{$ele[0]}[$ele[1]] = $element[1];
}
close IN;

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^#/);
  @element = split(/\t/,$line);

  $sv_type = $element[6];
  $sv_size = abs($element[7]);
  $chr1 = $element[0];
  $chr2 = $element[3];
  $pos1 = $element[1];
  $pos2 = $element[4];
  $ori1 = "[$element[2]]";
  $ori2 = "[$element[5]]";

  next if ($chr1 eq "Mt");
  next if ($chr1 eq "Pt");
  next if ($chr2 eq "Mt");
  next if ($chr2 eq "Pt");

  $freq{$sv_type} ++;

  $depth_val = ($depth{$chr1}[$pos1] + $depth{$chr2}[$pos2]) / 2;

  $key = "$chr1\t$pos1\t$chr2\t$pos2\t$sv_type";
  $inf{$key} = "$sv_size\t$ori1\t$ori2\t$element[8]\t$element[9]\t$depth_val";

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
  print STDERR "USAGE: makeBDList.pl bd.output\n";
  exit(-1);
}
