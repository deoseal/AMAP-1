#!/usr/bin/perl
#

&help if (@ARGV != 3);

open(IN,"<$ARGV[2]") or die;
while ($line = <IN>) {
  chomp($line);
  next if ($line =~ /^Model_name/);
  @element = split(/\t/,$line);
  $description{$element[0]} = $element[2];
}
close IN;

open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\t/,$line);
  next if (($element[2] ne "start_codon") && ($element[2] ne "stop_codon"));
  $chr = $element[0];
  $type = $element[1];
  $left = $element[3];
  $right = $element[4];
  
  $tid = "";
  $tname = "";
  @element = split(/\;/,$element[8]);
  for($i=0; $i<@element; $i++) {
    $element[$i] =~ s/^\s+//;
    @ele = split(/\s+/,$element[$i]);
    if ($ele[0] eq "transcript_id") {
      $tid = $ele[1];
    } elsif ($ele[0] eq "transcript_name") {
      $tname = $ele[1];
    }
  }
  $tid =~ s/\"//g;
  $tname =~ s/\"//g;

  if (exists $transcript_inf{$tid}) {
    $transcript_left{$tid} = $left if ($transcript_left{$tid} > $left);
    $transcript_right{$tid} = $right if ($transcript_right{$tid} < $right);
  } else {
    $transcript_inf{$tid} = "$tname:$type";
    $transcript_chr{$tid} = $chr;
    $transcript_left{$tid} = $left;
    $transcript_right{$tid} = $right;
  }
}
close IN;

foreach $tid (keys %transcript_inf) {
  $chr = $transcript_chr{$tid};
  $dat{tid} = $tid;
  $dat{left} = $transcript_left{$tid};
  $dat{right} = $transcript_right{$tid};
  $dat{inf} = $transcript_inf{$tid};
  push(@{$transcript{$chr}},{%dat});
}

open(IN,"<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\t/,$line);
  $chr[0] = $element[0];
  $chr[1] = $element[2];
  $pos[0] = $element[1];
  $pos[1] = $element[3];
  $ann[0] = "";
  $ann[1] = "";

  for($i=0; $i<=1; $i++) {
    for($j=0; $j<@{$transcript{$chr[$i]}}; $j++) {
      next if ($pos[$i] > $transcript{$chr[$i]}[$j]{right});
      next if ($pos[$i] < $transcript{$chr[$i]}[$j]{left});
      $tid = $transcript{$chr[$i]}[$j]{tid};
      if (exists $description{$tid}) {
        $desc = $description{$tid};
      } else {
        $desc = "";
      }
      $ann[$i] .= "$tid:$transcript{$chr[$i]}[$j]{inf}:$desc, ";
    }
    $ann[$i] = "none" if ($ann[$i] eq "");
  }

  for($i=0; $i<=5; $i++) {
    print STDOUT "$element[$i]\t";
  }
  print STDOUT "$ann[0]\t$ann[1]";
  for($i=6; $i<=11; $i++) {
    print STDOUT "\t$element[$i]";
  }
  print STDOUT "\n";
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: addGeneAnno_cnv.pl gtf cnv.list desc\n";
  exit(-1);
}
