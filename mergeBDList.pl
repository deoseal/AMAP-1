#!/usr/bin/perl
#

&help if (@ARGV < 1);

$sample_num = @ARGV;

for($i=0; $i<$sample_num; $i++) {
  open(IN, "<$ARGV[$i]") or die;
  while ($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);

    $key = "$element[0]\t$element[1]\t$element[2]\t$element[3]\t$element[4]";
    $common_inf{$key} = "$element[5]\t$element[6]\t$element[7]";
    if ($element[12] < 4 || $element[12] > 1001) {
      $filter = 'filtered';
    } else {
      $filter = 'not_filtered';
    }
    if ($element[12] > 0) {
      $ratio = $element[11]/$element[12];
    } else {
      $ratio = 'NA';
    }
    if ($ratio < 0.1) {
      $filter = 'filtered';
    }
    $sample_inf[$i]{$key} = "$element[8]\t$element[9]\t$element[10]\t$element[11]\t$element[12]\t$ratio\t$filter";

    unless (exists $key_list{$key}) {
      for($j=0; $j<$sample_num; $j++) {
        $key_list{$key}[$j] = 0;
      }
      $dat{chr1} = $element[0];
      $dat{chr2} = $element[2];
      $dat{pos1} = $element[1];
      $dat{pos2} = $element[3];
      $dat{type} = $element[4];
      $dat{key} = $key;
      $dat{cluster} = -1;
      push(@key_sort,{%dat});
    }
    $key_list{$key}[$i] = 1;
  }
  close IN;
}

@key_sort = sort{$a->{chr1}<=>$b->{chr1} || $a->{pos1}<=>$b->{pos1}} @key_sort;
$cluster = 0;
for ($i=0; $i<@key_sort; $i++) {
  next if ($key_sort[$i]{cluster} != -1);
  $cluster ++;
  $key_sort[$i]{cluster} = $cluster;
  for($j=0; $j<$sample_num; $j++) {
    $cluster_list{$cluster}[$j] = 0;
    $cluster_list{$cluster}[$j] = 1 if ($key_list{$key_sort[$i]{key}}[$j] == 1);
  }
  next if ($key_sort[$i]{type} eq "CTX");
  for ($j=$i+1; $j<@key_sort; $j++) {
    next if ($key_sort[$j]{cluster} != -1);
    next if ($key_sort[$i]{chr1} ne $key_sort[$j]{chr1});
    next if ($key_sort[$i]{pos1} > $key_sort[$j]{pos2});
    next if ($key_sort[$i]{pos2} < $key_sort[$j]{pos1});
    $max_pos1 = $key_sort[$i]{pos1};
    $max_pos1 = $key_sort[$j]{pos1} if ($max_pos1 < $key_sort[$j]{pos1});
    $min_pos2 = $key_sort[$i]{pos2};
    $min_pos2 = $key_sort[$j]{pos2} if ($min_pos2 > $key_sort[$j]{pos2});
    $len1 = $key_sort[$i]{pos2} - $key_sort[$i]{pos1} + 1;
    $len2 = $key_sort[$j]{pos2} - $key_sort[$j]{pos1} + 1;
    $duplen = $min_pos2 - $max_pos1 + 1;
    next if (($duplen / $len1 < 0.8) || ($duplen / $len2 < 0.8));
    $key_sort[$j]{cluster} = $cluster;
    for($k=0; $k<$sample_num; $k++) {
      $cluster_list{$cluster}[$k] = 1 if ($key_list{$key_sort[$j]{key}}[$k] == 1);
    }
  }
}

print STDERR "# CLUSTER : $cluster\n";

@key_sort = sort{$a->{cluster}<=>$b->{cluster} || $a->{chr1}<=>$b->{chr1} || $a->{pos1}<=>$b->{pos1}} @key_sort;

print STDOUT "\t\t\t\t\t\t\t\t\t\t\t\t\t";
for($i=0; $i<$sample_num; $i++) {
  print STDOUT "sample-$i\t\t\t\t\t\t\t";
}
print STDOUT "\n";
print STDOUT "Chr1\tPos1\tChr2\tPos2\tSV_type\tSV_size\tAnnot1\tAnnot2\tConsensus\tCluster\tCluster_consensus\tIGV_link1\tIGV_link2\t";
for($i=0; $i<$sample_num; $i++) {
  print STDOUT "Orient1\tOrient2\tScore\tRead_num\tDepth\tRatio\tFilter\t";
}
print STDOUT "\n";

foreach $cluster (keys %cluster_list) {
  $num = 0;
  for($i=0; $i<$sample_num; $i++) {
    $num ++ if ($cluster_list{$cluster}[$i] == 1);
  }
  if ($num == $sample_num) {
    $cluster_consensus{$cluster} = "common";
  } else {
    if ($num == 1) {
      $cluster_consensus{$cluster} = "not_common";
    } else {
      $cluster_consensus{$cluster} = "part_common";
    }
  }
}

foreach $key (keys %key_list) {
  $num = 0;
  for($i=0; $i<$sample_num; $i++) {
    $num ++ if ($key_list{$key}[$i] == 1);
  }
  if ($num == $sample_num) {
    $consensus{$key} = "common";
  } else {
    if ($num == 1) {
      $consensus{$key} = "not_common";
    } else {
      $consensus{$key} = "part_common";
    }
  }
}

for($i=0; $i<@key_sort; $i++) {
  $key = $key_sort[$i]{key};
  $cluster = $key_sort[$i]{cluster};

  $link1 = "\=HYPERLINK(\"http://localhost:60151/goto\?locus\=$key_sort[$i]{chr1}:$key_sort[$i]{pos1}\",\"link1\")";
  $link2 = "\=HYPERLINK(\"http://localhost:60151/goto\?locus\=$key_sort[$i]{chr2}:$key_sort[$i]{pos2}\",\"link2\")";

  print STDOUT "$key\t$common_inf{$key}\t$consensus{$key}\t$cluster\t$cluster_consensus{$cluster}\t$link1\t$link2\t";
  for($j=0; $j<$sample_num; $j++) {
    if (exists $sample_inf[$j]{$key}) {
      print STDOUT "$sample_inf[$j]{$key}\t";
    } else {
      print STDOUT "\t\t\t\t\t\t\t";
    }
  }
  print STDOUT "\n";
}

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: mergeBDList.pl bd.list1 ...\n";
  exit(-1);
}
