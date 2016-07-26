#!/usr/bin/perl

#Automated Mutation Analysis Pipeline (AMAP) ver. 1.0.
#
#Authors: Kotaro Ishii (kotaro@riken.jp),
#	 Yusuke Kazama (ykaze@riken.jp),
#	 Tomonari Hirano,
#	 Michiaki Hamada,
#	 Yukiteru Ono,
#	 and Tomoko Abe
#Date:	25/11/2015

use Cwd;
use File::Basename;

&help if (@ARGV != 1);

$cwdir = Cwd::getcwd();

open(STATS,">find_rearrangement.stats") or die;

#############
# configure #
#############

$num1 = -1;
$num2 = -1;
$num3 = -1;
open(IN,"<$ARGV[0]") or die;
while ($line = <IN>) {
  chomp($line);
  $line =~ s/^\s+$//;
  next if ($line eq "");
  @element = split(/\t/,$line);

  if ($element[0] eq "read1") {
    $num1 ++;
    $read1[$num1] = $element[1];
  } elsif ($element[0] eq "read2") {
    $num2 ++;
    $read2[$num2] = $element[1];
  } elsif ($element[0] eq "insert_size") {
    $num3 ++;
    $insert_size[$num3] = $element[1];
  } else {
    $cfg{$element[0]} = $element[1];
  }
}
close IN;

&execsys("cp $cfg{genome} ./");
$cfg{genome} = basename($cfg{genome});
$cfg{chrom_order} =~ s/\s+//g;

#####################
# database building #
#####################

&execsys("samtools faidx $cfg{genome}");
&execsys("bwa index -a is $cfg{genome}");
$dict = $cfg{genome};
$dict =~ s/fa$/dict/;
&execsys("java -Xmx2G -jar $cfg{picard_dir}/CreateSequenceDictionary.jar R=$cfg{genome} O=$dict");
&execsys("RepeatMasker -species $cfg{repeat_species} $cfg{genome}");
&execsys("mv $cfg{genome}.out $cfg{genome}.repeat");
&execsys("RepeatMasker -div 0.0 -species $cfg{repeat_species} $cfg{genome}");
&execsys("mv $cfg{genome}.out $cfg{genome}.repeat.div0");
&execsys("convertVcfForGATK.pl $cfg{known_snp} $cfg{chrom_order} > known_snp.conv");

###############################################################
###############################################################

for($i=0; $i<@read1; $i++) {

###############
# bwa mapping #
###############

  &execsys("countFastq.pl $read1[$i] > stat.$i-1");
  open(IN,"<stat.$i-1") or die;
  while($line = <IN>) {
    chomp($line);
    print STATS "$i\tread1_num\t$line\n";
  }
  close IN;

  &execsys("countFastq.pl $read2[$i] > stat.$i-2");
  open(IN,"<stat.$i-2") or die;
  while($line = <IN>) {
    chomp($line);
    print STATS "$i\tread2_num\t$line\n";
  }
  close IN;

  &execsys("bwa aln -t 1 $cfg{genome} $read1[$i] > read-$i-1.sai");
  &execsys("bwa aln -t 1 $cfg{genome} $read2[$i] > read-$i-2.sai");
  &execsys("bwa sampe $cfg{genome} read-$i-1.sai read-$i-2.sai $read1[$i] $read2[$i] -r\"\@RG\\tID:$i\\tSM:$i\\tPL:Illumina\" > read-$i.sam");
  &execsys("samtools view -bS read-$i.sam > read-$i.bam");
  &execsys("samtools sort read-$i.bam read-$i.sort");
  &execsys("samtools index read-$i.sort.bam");

  &execsys("samtools view read-$i.sort.bam | bwa2stat.pl > stat.$i-3");
  open(IN,"<stat.$i-3") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tmapping_num\t$element[0]\n";
    print STATS "$i\tmapping_num(paired-end)\t$element[1]\n";
  }
  close IN;

########################
# PCR-duplicate remove #
########################

  &execsys("java -Xmx2G -jar $cfg{picard_dir}/MarkDuplicates.jar I=read-$i.sort.bam O=read-$i.redup.bam METRICS_FILE=read-$i.sort.metrics REMOVE_DUPLICATES=true ASSUME_SORTED=true VALIDATION_STRINGENCY=LENIENT");
  &execsys("samtools index read-$i.redup.bam");

  &execsys("samtools view read-$i.redup.bam | bwa2stat.pl > stat.$i-4");
  open(IN,"<stat.$i-4") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tmapping_num(redup)\t$element[0]\n";
    print STATS "$i\tmapping_num(redup,paired-end)\t$element[1]\n";
  }
  close IN;

###############
# realignment #
###############

  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $cfg{genome} -I read-$i.redup.bam -log log.RealignerTargetCreator.$i -o read-$i.intervals");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T IndelRealigner -R $cfg{genome} -I read-$i.redup.bam -log log.IndelRealigner.$i -targetIntervals read-$i.intervals -o read-$i.realn.bam");
  &execsys("java -Xmx2G -jar $cfg{picard_dir}/FixMateInformation.jar I=read-$i.realn.bam O=read-$i.realn.fix.bam SO=coordinate VALIDATION_STRINGENCY=SILENT");
  &execsys("samtools index read-$i.realn.fix.bam");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T BaseRecalibrator -R $cfg{genome} -I read-$i.realn.fix.bam -knownSites known_snp.conv -log log.BaseRecalibrator.$i -o read-$i.recal.table");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T PrintReads -R $cfg{genome} -I read-$i.realn.fix.bam -BQSR read-$i.recal.table -log log.PrintReads.$i -o read-$i.recal.bam");
  &execsys("samtools index read-$i.recal.bam");
  &execsys("rm read-$i.recal.bai");

#####################
# depth of coverage #
#####################

  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T DepthOfCoverage -R $cfg{genome} -I read-$i.recal.bam -o read-$i.depth -ct 10 -ct 20 -ct 30 -ct 40 -ct 50");
  open(IN,"<read-$i.depth.sample_summary") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\s+/,$line);
    next if ($element[0] ne $i);
    print STATS "$i\tdepth(mean)\t$element[2]\n";
    print STATS "$i\tdepth(median)\t$element[4]\n";
    print STATS "$i\tdepth(10x,%)\t$element[6]\n";
    print STATS "$i\tdepth(20x,%)\t$element[7]\n";
    print STATS "$i\tdepth(30x,%)\t$element[8]\n";
    print STATS "$i\tdepth(40x,%)\t$element[9]\n";
    print STATS "$i\tdepth(50x,%)\t$element[10]\n";
  }
  close IN;

##################
# SNV (samtools) #
##################

  &execsys("samtools mpileup -uf $cfg{genome} read-$i.recal.bam | bcftools view -bvcg - > read-$i.snv.bcf");
  &execsys("bcftools view read-$i.snv.bcf | vcfutils.pl varFilter -p -d 5 -D 1000 > read-$i.snv.notf.vcf 2> read-$i.snv.fil.vcf");
  &execsys("mergeSnvVcf.pl read-$i.snv.notf.vcf read-$i.snv.fil.vcf > read-$i.snv.vcf 2> read-$i.snv.stat");

  open(IN,"<read-$i.snv.stat") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tSNV_num(SAMtools,not_filtered)\t$element[0]\n";
    print STATS "$i\tSNV_num(SAMtools,filtered)\t$element[1]\n";
  }
  close IN;

  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/SnpSift.jar annotate -id known_snp.conv read-$i.snv.vcf > read-$i.snv.ann1.vcf.tmp");
  &execsys("addId.pl read-$i.snv.ann1.vcf.tmp > read-$i.snv.ann1.vcf");
  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/snpEff.jar eff -o txt -a 5 -c $cfg{snpeff_cfg} -v $cfg{snpeff_species} read-$i.snv.ann1.vcf > read-$i.snv.ann2.txt");
  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/snpEff.jar eff -o vcf -c $cfg{snpeff_cfg} -v $cfg{snpeff_species} read-$i.snv.ann1.vcf > read-$i.snv.ann2.vcf");
  &execsys("replaceSnvPos.pl read-$i.snv.ann2.vcf read-$i.snv.ann2.txt > read-$i.snv.ann3.txt");
  &execsys("compareRM.pl $cfg{genome}.repeat read-$i.snv.ann3.txt > read-$i.snv.ann4.txt");
  &execsys("compareRM.pl $cfg{genome}.repeat.div0 read-$i.snv.ann4.txt > read-$i.snv.ann5.txt");
  &execsys("makeSnvList.pl read-$i.snv.ann2.vcf read-$i.snv.ann5.txt $cfg{gene_description} > read-$i.snv.list");

##############
# SNV (GATK) #
##############

  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T UnifiedGenotyper -R $cfg{genome} -I read-$i.recal.bam -D known_snp.conv -A AlleleBalance -stand_call_conf 50.0 -stand_emit_conf 10.0 -dcov 200 -glm SNP -out_mode EMIT_VARIANTS_ONLY -log log.UnifiedGenotyper-snp.$i -o read-$i.snv-gatk-snp.vcf");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T VariantFiltration -R $cfg{genome} -V read-$i.snv-gatk-snp.vcf --clusterWindowSize 10 --filterExpression \"QUAL < 30.0 || QD < 5.0\" --filterName \"HARD_TO_VALIDATE\" -log log.VariantFiltration-snp.$i -o read-$i.snv-gatk-snp.fil.vcf");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T UnifiedGenotyper -R $cfg{genome} -I read-$i.recal.bam -D known_snp.conv -A AlleleBalance -stand_call_conf 50.0 -stand_emit_conf 10.0 -dcov 200 -glm INDEL -out_mode EMIT_VARIANTS_ONLY -log log.UnifiedGenotyper-indel.$i -o read-$i.snv-gatk-indel.vcf");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T VariantFiltration -R $cfg{genome} -V read-$i.snv-gatk-indel.vcf --clusterWindowSize 10 --filterExpression \"QUAL < 10.0\" --filterName \"HARD_TO_VALIDATE_1\" --filterExpression \"MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)\" --filterName \"HARD_TO_VALIDATE_2\" -log log.VariantFiltration-indel.$i -o read-$i.snv-gatk-indel.fil.vcf");
  &execsys("java -Xmx2G -jar $cfg{gatk_dir}/GenomeAnalysisTK.jar -T CombineVariants -R $cfg{genome} --variant read-$i.snv-gatk-snp.fil.vcf --variant read-$i.snv-gatk-indel.fil.vcf -o read-$i.snv-gatk.vcf.tmp -log log.CombineVariants.$i");
  &execsys("convertSnvGATKVcf.pl read-$i.snv-gatk.vcf.tmp > read-$i.snv-gatk.vcf 2> read-$i.snv-gatk.stat");

  open(IN,"<read-$i.snv-gatk.stat") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tSNV_num(GATK,not_filtered)\t$element[0]\n";
    print STATS "$i\tSNV_num(GATK,filtered)\t$element[1]\n";
  }
  close IN;

  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/SnpSift.jar annotate -id known_snp.conv read-$i.snv-gatk.vcf > read-$i.snv-gatk.ann1.vcf.tmp");
  &execsys("addId.pl read-$i.snv-gatk.ann1.vcf.tmp > read-$i.snv-gatk.ann1.vcf");
  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/snpEff.jar eff -o txt -a 5 -c $cfg{snpeff_cfg} -v $cfg{snpeff_species} read-$i.snv-gatk.ann1.vcf > read-$i.snv-gatk.ann2.txt");
  &execsys("java -Xmx2g -jar $cfg{snpeff_dir}/snpEff.jar eff -o vcf -c $cfg{snpeff_cfg} -v $cfg{snpeff_species} read-$i.snv-gatk.ann1.vcf > read-$i.snv-gatk.ann2.vcf");
  &execsys("replaceSnvPos.pl read-$i.snv-gatk.ann2.vcf read-$i.snv-gatk.ann2.txt > read-$i.snv-gatk.ann3.txt");
  &execsys("compareRM.pl $cfg{genome}.repeat read-$i.snv-gatk.ann3.txt > read-$i.snv-gatk.ann4.txt");
  &execsys("compareRM.pl $cfg{genome}.repeat.div0 read-$i.snv-gatk.ann4.txt > read-$i.snv-gatk.ann5.txt");
  &execsys("makeSnvList.pl read-$i.snv-gatk.ann2.vcf read-$i.snv-gatk.ann5.txt $cfg{gene_description} > read-$i.snv-gatk.list");

##########
# pindel #
##########

  open(OUT,">read-$i.pindel.config") or die;
  print OUT "read-$i.recal.bam\t$insert_size[$i]\tread-$i\n";
  close OUT;

  &execsys("pindel -f $cfg{genome} -i read-$i.pindel.config -c ALL -o read-$i.pindel");
  &execsys("cat read-$i.pindel_TD read-$i.pindel_SI read-$i.pindel_INV read-$i.pindel_D read-$i.pindel_BP read-$i.pindel_LI > read-$i.pindel_ALL");
  &execsys("makePindelList.pl read-$i.pindel_ALL read-$i.depth > read-$i.pindel.list.tmp 2> read-$i.pindel.stat");
  &execsys("addGeneAnno_pindel.pl $cfg{known_gene} read-$i.pindel.list.tmp $cfg{gene_description} > read-$i.pindel.list");

  open(IN,"<read-$i.pindel.stat") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tPindel_num\t$element[0]\t$element[1]\n";
  }
  close IN;

###############
# breakdancer #
###############

  &execsys("java -jar -Xmx2G $cfg{picard_dir}/AddOrReplaceReadGroups.jar INPUT=read-$i.recal.bam OUTPUT=read-$i.recal.rg.bam SORT_ORDER=coordinate RGID=$i RGLB=$i RGPL=Illumina RGSM=$i RGPU=$i CREATE_INDEX=True VALIDATION_STRINGENCY=LENIENT");
  &execsys("bam2cfg.pl read-$i.recal.rg.bam > read-$i.bd.cfg");
  &execsys("breakdancer-max read-$i.bd.cfg > read-$i.bd");
  &execsys("makeBDList.pl read-$i.bd read-$i.depth > read-$i.bd.list.tmp 2> read-$i.bd.stat");
  &execsys("addGeneAnno_bd.pl $cfg{known_gene} read-$i.bd.list.tmp $cfg{gene_description} > read-$i.bd.list");

  open(IN,"<read-$i.bd.stat") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tBreakdancer_num\t$element[0]\t$element[1]\n";
  }
  close IN;

############
# CNVnator #
############

  &execsys("toSingleFasta.pl $cfg{genome}");
  &execsys("cnvnator -root read-$i.root -tree read-$i.recal.bam");
  &execsys("cnvnator -root read-$i.root -his 1000");
  &execsys("cnvnator -root read-$i.root -stat 1000");
  &execsys("cnvnator -root read-$i.root -partition 1000");
  &execsys("cnvnator -root read-$i.root -call 1000 > read-$i.cnv");
  &execsys("cnv2region.pl read-$i.cnv > read-$i.geno.in");
  &execsys("cat read-$i.geno.in | cnvnator -root read-$i.root -genotype 1000 > read-$i.cnv.geno");
  &execsys("makeCNVList.pl read-$i.cnv read-$i.cnv.geno read-$i.depth > read-$i.cnv.list.tmp 2> read-$i.cnv.stat");
  &execsys("addGeneAnno_cnv.pl $cfg{known_gene} read-$i.cnv.list.tmp $cfg{gene_description} > read-$i.cnv.list");

  open(IN,"<read-$i.cnv.stat") or die;
  while($line = <IN>) {
    chomp($line);
    @element = split(/\t/,$line);
    print STATS "$i\tCNV_num\t$element[0]\t$element[1]\n";
  }
  close IN;
}

################
# List merging #
################

$snvlist = "";
$pindellist = "";
$bdllist = "";
$cnvlist = "";
for($i=0; $i<@read1; $i++) {
  $snvlist .= " read-$i.snv.list";
  $snvgatklist .= " read-$i.snv-gatk.list";
  $pindellist .= " read-$i.pindel.list";
  $bdlist .= " read-$i.bd.list";
  $cnvlist .= " read-$i.cnv.list";
}
&execsys("mergeSnvList.pl $snvlist > snv.list");
&execsys("mergeGatkList.pl $snvgatklist > snv-gatk.list");
&execsys("mergePindelList.pl $pindellist > pindel.list");
&execsys("mergeBDList.pl $bdlist > bd.list");
&execsys("mergeCNVList.pl $cnvlist > cnv.list");
&execsys("mergeBP.pl pindel.list bd.list cnv.list 10000 > bp.summary");
close STATS;

exit (0);


### SUB: help
sub help {
  print STDERR "USAGE: find_rearrangement.pl cfg\n";
  exit (-1);
}

### SUB: execsys
sub execsys {
  $cmd = "cd $cwdir; @_";
  print STDOUT "###\n$cmd\n\n";
  if (system($cmd)) {
    print STDERR "\nERROR !!! : $cmd\n\n";
    exit (-1);
  }
}
