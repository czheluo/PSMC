#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($vcf,$gro,$out,$dsh,$maf,$mis,$dep);        
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.1.0";
GetOptions(
	"help|?" =>\&USAGE,    
	"vcf:s"=>\$vcf,
	"gro:s"=>\$gro,
	"out:s"=>\$out,
	"dsh:s"=>\$dsh,
	"maf:s"=>\$maf,
	"mis:s"=>\$mis,
	"dep:s"=>\$dep,
			) or &USAGE;
&USAGE unless ($vcf and $out and $gro); 
#######################################################################################
$vcf=ABSOLUTE_DIR($vcf);
$gro=ABSOLUTE_DIR($gro);
mkdir $out if (!-d $out);
$out=ABSOLUTE_DIR($out);
$dsh||="$out/work_sh";
mkdir $dsh if (!-d $dsh);
$dsh=ABSOLUTE_DIR($dsh);
$mis||=0.3;
$maf||=0.05;
$dep||=2;
$mis=1-$mis;
my $indv;
open GRO,$gro;
while (<GRO>){
	chomp;
	next if ($_ eq ""||/^$/);
	my ($sample,undef) = split /\s+/;
	$indv .= "--indv $sample ";
}
close GRO;
open SH,">$dsh/step01.vcf-filter.sh";
print SH "vcftools --remove-filtered-all --remove-indels --minDP $dep --max-missing $mis --maf $maf $indv  --vcf $vcf --recode --out $out/treemix  && perl $Bin/bin/remakegrolist.pl -in $gro -out $out/treemix.group.list && python $Bin/bin/vcf2treemix.py -vcf $out/treemix.recode.vcf -pop $out/treemix.group.list -out $out && cd $out && gzip $out/pop.tmix \n";
close SH;
my $job="qsub-slurm.pl $dsh/step01.vcf-filter.sh";
#`$job`;
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

sub USAGE {           
        my $usage=<<"USAGE";
Contact:	meng.luo\@majorbio.com
Version:	$version
Add:		vcf-filte only save group Individuals
Script:		$Script
Description:	step01.vcf-filter.pl for treemix
Usage:
  Options:
	-vcf  <file>  input vcf files; must
	-gro  <file>  input group list; split by \\t; must
	-out  <dir>   output dir; must
	-dsh  <dir>   output work shell
	-maf  <num>   maf filter default 0.05
	-mis  <num>   mis filter default 0.3
	-dep  <num>   dep filter default 2
	-h	Help

USAGE
        print $usage;
        exit;
}
