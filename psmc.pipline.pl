#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($vcf,$out,$num,$order,$root,$maf,$mis,$dep,$gro,$step,$stop);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"vcf:s"=>\$vcf,
	"gro:s"=>\$gro,
    "num:s"=>\$num,
    "order:s"=>\$order,
    "root:s"=>\$root,
	"out:s"=>\$out,
	"maf:s"=>\$maf,
	"mis:s"=>\$mis,
	"dep:s"=>\$dep,
	"step:s"=>\$step,
    "stop:s"=>\$stop,
			) or &USAGE;
&USAGE unless ($vcf and $order and $out and $gro and $num);
mkdir $out if (!-d $out);
mkdir "$out/work_sh" if (!-d "$out/work_sh");
$out=ABSOLUTE_DIR($out);
$vcf=ABSOLUTE_DIR($vcf);
$gro=ABSOLUTE_DIR($gro);
$step||=1;
$stop||=-1;
$maf||=0.05;
$mis||=0.3;
$dep||=2;
$order=ABSOLUTE_DIR($order);
open Log,">$out/work_sh/pop.$BEGIN_TIME.log";
if ($step == 1) {
	print Log "########################################\n";
	print Log "variant-filer \n",my $time=time(),"\n";
	print Log "########################################\n";
	my $job="perl $Bin/bin/step01.vcf-filter.pl -vcf $vcf -gro $gro -out $out/step01.vcf-filter -dsh $out/work_sh -maf $maf -mis $mis -dep $dep";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "variant-filter Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step ==2) {
	print Log "########################################\n";
	print Log "run treemix \n",my $time=time(),"\n";
	print Log "########################################\n";
	my $tree=ABSOLUTE_DIR("$out/step01.vcf-filter/pop.tmix.gz");
	my $job="perl $Bin/bin/step02.treemix.pl -tree $tree -num $num -out $out/step02.treemix -dsh $out/work_sh ";
	if (defined $root){
		$job .= " -root $root ";
	}
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "run treemix Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
    $step++ if ($step ne $stop);
}
if ($step ==3) {
	print Log "########################################\n";
	print Log "plot treemix \n",my $time=time(),"\n";
	print Log "########################################\n";
	my $list=ABSOLUTE_DIR("$out/step02.treemix/treemix.list");
	my $job="perl $Bin/bin/step03.drawplot.pl -list $list -order $order -out $out/step03.drawplot -dsh $out/work_sh ";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "plot treemix Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
if ($step ==4) {
	print Log "########################################\n";
	print Log "arrange result\n",my $time=time(),"\n";
	print Log "########################################\n";
	mkdir "$out/step04.result" if (!-d "$out/step04.result");
	my $job="perl $Bin/bin/step04.result.pl -out $out";
	print Log "$job\n";
	`$job`;
	print Log "$job\tdone!\n";
	print Log "########################################\n";
	print Log "arrange result Done and elapsed time : ",time()-$time,"s\n";
	print Log "########################################\n";
	$step++ if ($step ne $stop);
}
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

sub USAGE {#
        my $usage=<<"USAGE";
Contact:        tong.wang\@majorbio.com;
Version:	$version;
Script:		$Script
Description:
	treemix pipline
Usage:

	-vcf	<file>	input vcf file; must
	-out	<dir>	output dir; must
	-gro	<file>	input group list; must
	-num    <num>	sum group number; must; must >1 	
	-root   <str>	choose root from group list(groupname); must; can multi(,delimit)
	-order  <file>	groupname list; one line one groupname; must;
	-maf	<num>	maf default 0.05
	-mis	<num>	mis default 0.3
	-dep	<num>	dep default 2
	-step   <num>	start pipiline control
	-stop   <num>	end pipiline control
	-h			Help

USAGE
        print $usage;
        exit;
}
