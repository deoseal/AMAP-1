#!/usr/bin/perl
#

&help if (@ARGV != 1);

$id = "";
open(IN, "<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  if ($line =~ /^>/) {
    close OUT if ($id ne "");
    @element = split(/\s+/,$line);
    $id = $element[0];
    $id =~ s/^>//;
    $id = "chr$id" if ($id !~ /^chr/);
    open(OUT,">$id.fa") or die;
    print OUT ">$id\n";
  } else {
    print OUT "$line\n";
  }
}
close IN;
close OUT;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: toSingleFasta.pl fasta\n";
  exit(-1);
}
