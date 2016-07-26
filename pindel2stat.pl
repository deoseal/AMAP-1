#!/usr/bin/perl
#

open(IN,"$ARGV[0]") or die;
while($line=<IN>) {
  chomp($line);
  next if ($line =~ /^#/);
  @element = split(/\s+/,$line);
  next if ($element[0] eq "Mt");
  next if ($element[0] eq "Pt");
  $info = $element[7];
  @ele = split(/\;/,$info);
  
  $svlen = 0;
  $svtype = "";
  for($i=0; $i<@ele; $i++) {
    ($item,$val) = split(/\=/,$ele[$i]);
    $svlen = abs($val) if ($item eq "SVLEN");
    $svtype = $val if ($item eq "SVTYPE");
  }
  if ($svtype eq "") {
    print STDERR "ERROR : $line\n";
    exit(-1);
  }
  $freq1{$svtype} ++;
  $freq2{$svtype} ++ if ($svlen >= 10);
}
close IN;

foreach $type (keys %freq1) {
  print STDOUT "$type\t$freq1{$type}\t$freq2{$type}\n";
}

exit (0);
