#!/usr/bin/perl
#

&help if (@ARGV != 4);

@prog = ("PINDEL","BREAKDANCER","CNVNATOR");

$distance = $ARGV[3];

$bp_num = 0;
for($i=0; $i<3; $i++) {
  $num = 0;
  open(IN, "<$ARGV[$i]") or die;
  while ($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);

    $num ++;
    next if ($num <= 2);

    $sample = "";
    $width = 3 if ($i == 0);
    $width = 5 if ($i == 1);
    $width = 6 if ($i == 2);
    for($j=13; $j<@element; $j+=$width) {
      if ($element[$j] ne "") {
        $snum = ($j - 13) / $width;
        $sample .= "sample-$snum,";
      }
    }
    $sample =~ s/\,$//;

    $bp_num ++;
    $dat{clu_num} = -1;
    $dat{meta_num} = -1;
    $dat{inf} = "$element[0]\t$element[1]\t$element[2]\t$element[3]\t$prog[$i]\t$element[4]\t$element[5]\t$element[8]\t$element[10]\t$sample";
    $dat{chr} = $element[0];
    $dat{pos} = $element[1];
    $dat{bp_num} = $bp_num;
    push(@bp,{%dat});
    $dat{chr} = $element[2];
    $dat{pos} = $element[3];
    push(@bp,{%dat});
  }
}

@bp = sort{$a->{chr}<=>$b->{chr} || $a->{pos}<=>$b->{pos}} @bp;

$clu_num = 0;
for ($i=0; $i<@bp; $i++) {
  $left = $bp[$i]{pos} - $distance;
  $right = $bp[$i]{pos} + $distance;
  for ($j=1; $j<=$clu_num; $j++) {
    next if ($bp[$i]{chr} ne $clu[$j]{chr});
    next if ($bp[$i]{pos} > $clu[$j]{right});
    next if ($bp[$i]{pos} < $clu[$j]{left});
    $bp[$i]{clu_num} = $j;
    $clu[$j]{left} = $left if($clu[$j]{left} > $left);
    $clu[$j]{right} = $right if($clu[$j]{right} < $right);
    last;
  }

  next if ($bp[$i]{clu_num} != -1);

  $clu_num ++;
  $bp[$i]{clu_num} = $clu_num;
  $clu[$clu_num]{chr} = $bp[$i]{chr};
  $clu[$clu_num]{left} = $left;
  $clu[$clu_num]{right} = $right;
}

$meta_num = 0;
for ($i=0; $i<@bp; $i++) {
  $tmp_bp = $bp[$i]{bp_num};
  $tmp_clu = $bp[$i]{clu_num};

  if (exists $bp2meta{$tmp_bp}) {
    $meta1 = $bp2meta{$tmp_bp};
    if (exists $clu2meta{$tmp_clu}) {
      $meta2 = $clu2meta{$tmp_clu};

      if ($meta1 != $meta2) {
        foreach $key (keys %{$metaclu[$meta1]}) {
          $clu2meta{$key} = $meta2;
          $metaclu[$meta2]{$key} = 1;
          delete($metaclu[$meta1]{$key});
        }
        foreach $key (keys %{$metabp[$meta1]}) {
          $bp2meta{$key} = $meta2;
          $metabp[$meta2]{$key} = 1;
          delete($metabp[$meta1]{$key});
        }
      }

    } else {
      $clu2meta{$tmp_clu} = $meta1;
      $metaclu[$meta_num]{$tmp_clu} = 1;
    }
  } else {
    if (exists $clu2meta{$tmp_clu}) {
      $meta2 = $clu2meta{$tmp_clu};
      $bp2meta{$tmp_bp} = $meta2;
      $metabp[$meta2]{$tmp_bp} = 1;
    } else {
      $meta_num ++;
      $bp2meta{$tmp_bp} = $meta_num;
      $metabp[$meta_num]{$tmp_bp} = 1;
      $clu2meta{$tmp_clu} = $meta_num;
      $metaclu[$meta_num]{$tmp_clu} = 1;
    }
  }
}

foreach $key (keys %clu2meta) {
  if (exists $data{$clu2meta{$key}}) {
    $data{$clu2meta{$key}} = $key if ($data{$clu2meta{$key}} > $key);
  } else {
    $data{$clu2meta{$key}} = $key;
  }
}
$num = 0;
foreach $key (sort{$data{$a}<=>$data{$b}} keys %data) {
  $num ++;
  $newmeta{$key} = $num;
}

for ($i=0; $i<@bp; $i++) {
  $tmp_meta = $newmeta{$clu2meta{$bp[$i]{clu_num}}};
  $tmp_bp = $bp[$i]{bp_num};
  $bp[$i]{meta_num} = $tmp_meta;
  next if (exists $counted{$tmp_bp});
  $meta2num{$tmp_meta} ++;
  $counted{$tmp_bp} = 1;
}

@bp = sort{$a->{meta_num}<=>$b->{meta_num} || $a->{chr}<=>$b->{chr} || $a->{pos}<=>$b->{pos}} @bp;

$num = 0;
for($i=0; $i<@bp; $i++) {
  next if ($meta2num{$bp[$i]{meta_num}} <= 1);
  if ($bp[$i]{meta_num} != $tmp_meta) {
    $num ++;
    print STDOUT "##### $num #####\n";
    $tmp_meta = $bp[$i]{meta_num};
  }
  next if (exists $outputed{$bp[$i]{bp_num}});
  print STDOUT "$bp[$i]{inf}\n";
  $outputed{$bp[$i]{bp_num}} = 1;
}
  
exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: mergeBP2.pl pindel.list bd.list cnv.list distance\n";
  exit(-1);
}
