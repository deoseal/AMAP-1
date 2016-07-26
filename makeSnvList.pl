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
  next if ($line =~ /^#/);

  @element = split(/\t/,$line);
  $key = $element[2];
  $vcf_filtered{$key} = $element[6];
  $vcf_mappingqual{$key} = 0;
  $vcf_baseref{$key} = 0;
  $vcf_basealt{$key} = 0;

  @element = split(/\;/,$element[7]);
  for($i=0; $i<@element; $i++) {
    @ele = split(/\=/,$element[$i]);
    if ($ele[0] eq "MQ") {
      $vcf_mappingqual{$key} = $ele[1];
    } elsif ($ele[0] eq "DP4") {
      @wk = split(/\,/,$ele[1]);
      $vcf_baseref{$key} = $wk[0] + $wk[1];
      $vcf_basealt{$key} = $wk[2] + $wk[3];
    }
  }
}
close IN;

open(IN,"<$ARGV[1]") or die;
while ($line = <IN>) {
  chomp($line);
  @element = split(/\t/,$line);
  next if ($element[0] eq "Mt");
  next if ($element[0] eq "Pt");

  $key = $element[23];
  $chr = $element[0];
  $position = $element[1];
  $reference = $element[2];
  $change = $element[3];
  $change_type = $element[4];

  $gene_id = $element[9];
  $gene_name = $element[10];
  $bio_type = $element[11];
  $transcript_id = $element[12];
  $cds_size = $element[20];

  $homozygous = $element[5];
  $quality = $element[6];
  $coverage = $element[7];
  $exon_id = $element[13];
  $exon_rank = $element[14];
  $effect = $element[15];
  $aa = $element[16];
  $codon = $element[17];
  $codon_num = $element[18];
  $codon_degeneracy = $element[19];
  $codons_around = $element[21];
  $aas_around = $element[22];
  $custom_interval_id = $element[23];
  $rep_inf1 = $element[24];
  $rep_inf2 = $element[25];
  $mapping_qual = $vcf_mappingqual{$key};
  $baseref = $vcf_baseref{$key};
  $basealt = $vcf_basealt{$key};
  $filtered = $vcf_filtered{$key};
  $rep_filtered = "Not_Filtered";

  @element = split(/\,/,$rep_inf2);
  for($i=0; $i<@element; $i++) {
    @ele = split(/\:/,$element[$i]);
    next if ($ele[1] ne "Simple_repeat");
    @wk = split(/[()]/,$ele[0]);
    $unit_size = length($wk[1]);
    $rep_size = $ele[3] - $ele[2] + 1;
    $unit_num = int($rep_size / $unit_size);
    $rep_filtered = "Filtered" if (($rep_size >= 10) && ($unit_num >= 5));
  }

  if ($custom_interval_id =~ /^None/) {
    $custom_interval_id = "";
  } else {
    @element = split(/\:/,$custom_interval_id);
    $custom_interval_id = $element[0];
  }

  print STDOUT "$chr\t$position\t$reference\t$change\t$change_type\t$effect\t$transcript_id";
  print STDOUT "\t$gene_id\t$gene_name\t$bio_type\t$cds_size\t$description{$transcript_id}\t$exon_id\t$exon_rank\t$aa\t$codon\t$codon_num\t$codon_degeneracy\t$codons_around\t$aas_around\t$rep_inf1\t$rep_inf2\t$rep_filtered";
  print STDOUT "\t$homozygous\t$quality\t$coverage\t$custom_interval_id\t$mapping_qual\t$baseref\t$basealt\t$filtered\n";
}
close IN;

exit(0);


### SUB : help
sub help {
  print STDERR "USAGE: makeSnvList.pl read-0.snv.snp.eff.vcf read-0.snv.snp.eff.rm.txt TAIR10_functional_descriptions\n";
  exit(-1);
}
