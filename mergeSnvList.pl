#!/usr/bin/perl
#

&help if (@ARGV < 1);

$sample_num = @ARGV;

for($i=0; $i<$sample_num; $i++) {
  open(IN, "<$ARGV[$i]") or die;
  while ($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    $element[3] = "\'$element[3]";

    $key = $element[0];
    for($j=1; $j<=6; $j++) {
      $key .= "\t$element[$j]";
    }

    $wkdata = $element[7];
    for($j=8; $j<=22; $j++) {
      $wkdata .= "\t$element[$j]";
    }
    if (exists $common_inf{$key}) {
      if ($wkdata ne $common_inf{$key}) {
        print STDERR "## ERROR : $key\n$wkdata\n$common_inf{$key}\n";
        #exit(-1);
      }
    } else {
      $common_inf{$key} = $wkdata;
    }

    $sample_inf[$i]{$key} = $element[23];
    for($j=24; $j<=30; $j++) {
      $sample_inf[$i]{$key} .= "\t$element[$j]";
    }
    next if (exists $keylist{$key});
    $keylist{$key} = 1;
    $dat{chr} = $element[0];
    $dat{pos} = $element[1];
    $dat{key} = $key;
    push(@keysort,{%dat});
  }
  close IN;
}

@keysort = sort{$a->{chr}<=>$b->{chr} || $a->{pos}<=>$b->{pos}} @keysort;

print STDOUT "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t";
for($i=0; $i<$sample_num; $i++) {
  print STDOUT "\tsample-$i\t\t\t\t\t\t\t";
}
print STDOUT "\n";
print STDOUT "Chr\tPosition\tReference\tChange\tChange_type\tEffect\tTranscript_ID\tGene_ID\tGene_name\tBio_type\tCDS_size\tDescription\tExon_ID\tExon_rank\tOld_AA/New_AA\tOld_codon/New_codon\tCodon_num(CDS)\tCodon_degeneracy\tCodons_around\tAAs_around\tMatching_repeat1\tMatching_repeat2\tRepeat_filtered\tConsensus\tIGVlink";
for($i=0; $i<$sample_num; $i++) {
  print STDOUT "\tHomozygous\tQuality\tCoverage\tCustom_interval_ID\tMappingQual\tHighQualBaseRef\tHighQualBaseAlt\tFiltered";
}
print STDOUT "\n";

for($i=0; $i<@keysort; $i++) {
  $key = $keysort[$i]{key};
  $num = 0;
  for($j=0; $j<$sample_num; $j++) {
    $num ++ if (exists $sample_inf[$j]{$key});
  }
  if ($num == $sample_num) {
    $consensus = "common";
  } else {
    if ($num == 1) {
      $consensus = "not_common";
    } else {
      $consensus = "part_common";
    }
  }

  $igv_link = "\=HYPERLINK(\"http://localhost:60151/goto\?locus\=$keysort[$i]{chr}:$keysort[$i]{pos}\",\"link\")";

  print STDOUT "$key\t$common_inf{$key}\t$consensus\t$igv_link";
  for($j=0; $j<$sample_num; $j++) {
    if (exists $sample_inf[$j]{$key}) {
      print STDOUT "\t$sample_inf[$j]{$key}";
    } else {
      print STDOUT "\t\t\t\t\t\t\t\t";
    }
  }
  print STDOUT "\n";
}

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: mergeSnvList.pl snv.list1 snv.list2 ...\n";
  exit(-1);
}
