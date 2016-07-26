#!/usr/bin/perl
#

&help if (@ARGV != 2);

open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^#/) {
    print STDOUT "$line\n";
    next;
  }
  @element = split(/\t/,$line);
  next if ($element[3] !~ /^[ATGC]+$/);
  $chr = $element[0];

  @snv = split(/\,/,$element[4]);
  $snvlist = "";
  for($i=0; $i<@snv; $i++) {
    $snvlist .= "$snv[$i]," if ($snv[$i] =~ /^[ATGC]+$/);
  }
  $snvlist =~ s/\,$//;
  next if ($snvlist eq "");

  $dat{pos} = $element[1];
  $dat{line} = "$element[0]\t$element[1]\t$element[2]\t$element[3]\t$snvlist\t$element[5]\t$element[6]\t$element[7]";
  push(@{$data{$chr}},{%dat});
}
close IN;

@chrom_order = split(/\,/,$ARGV[1]);

for($i=0; $i<@chrom_order; $i++) {
  $chr = $chrom_order[$i];
  @{$data{$chr}} = sort{$a->{pos}<=>$b->{pos}} @{$data{$chr}};
  for($j=0; $j<@{$data{$chr}}; $j++) {
    print STDOUT "$data{$chr}[$j]{line}\n";
  }
}

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: convertVcfForGATK.pl vcf chrom_order\n";
  exit(-1);
}
