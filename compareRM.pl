#!/usr/bin/perl
#

&help if (@ARGV != 2);

open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  $line =~ s/^\s+//;
  next if ($line !~ /^\d+/);

  @element = split(/\s+/,$line);
  $chr = $element[4];
  $dat{left} = $element[5];
  $dat{right} = $element[6];
  $dat{strand} = $element[8];
  $dat{name} = "$element[9]:$element[10]:$element[5]:$element[6]";
  push(@{$rep{$chr}},{%dat});
}
close IN;

foreach $chr (keys %rep) {
  @{$rep{$chr}} = sort{$a->{left} <=> $b->{left}} @{$rep{$chr}};
}

open(IN,"<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^#/);

  @element = split(/\t/,$line);
  $chr = $element[0];
  $left = $element[1] - 10;
  $right = $element[1] + 10;

  $repinf = "";
  for($i=0; $i<@{$rep{$chr}}; $i++) {
    last if ($right < $rep{$chr}[$i]{left});
    next if ($left > $rep{$chr}[$i]{right});
    $repinf .= "$rep{$chr}[$i]{name},";
  }
  $repinf =~ s/\,$//;
  print STDOUT "$line\t$repinf\n";
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: compRM.pl rm.out snpEff.out\n";
  exit(-1);
}
