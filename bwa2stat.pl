#!/usr/bin/perl
#

while ($line = <STDIN>) {
  chomp($line);
  next if ($line =~ /^\@/);
  @element = split(/\t/,$line);

  $bin = sprintf("%012b",$element[1]);
  if (substr($bin,10,1) == 1) {
    $pair_map ++;
    $map ++;
  } elsif (substr($bin,9,1) == 0) {
    $map ++;
  }
}

print STDOUT "$pair_map\t$map\n";

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: bwa2stat.pl < sam\n";
  exit(-1);
}
