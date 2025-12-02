#!/usr/bin/env perl
#===============================================================================
#
#         FILE: z.admixture.pl
#
#        USAGE: ./z.admixture.pl
#
#  DESCRIPTION: :
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Zeyu Zheng (Lanzhou University), zhengzy2014@lzu.edu.cn
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 10/30/2017 05:25:12 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use v5.10;
use MCE::Loop;
use File::Basename;
use zzRun;

sub help() {
	die "usage: perl xx.pl [A/P/N]  admixturePCAnj_dir vcf_base_name
A16 : ADMIXTURE, K=1~6
P : PCA
N : NJ";
}

my $admix_thread = 32;

my $admixture_max=6;
my $admixture_min=1;

my $run_type = shift or &help();
my $admixturePCAnj_dir= shift or &help();
#my $pre_dir='';
my $vcf = shift or &help();

my ($ADMIXTURE, $PCA, $NJ);
if ( $run_type =~/^A/ ) {
	if ( $run_type =~ /^A(\d)(\d)/ ) {
		$ADMIXTURE = 1;
		$admixture_min=$1;
		$admixture_max=$2;
	} else {die;}
} elsif ($run_type eq 'P') {
	$PCA=1;
} elsif ($run_type eq 'N') {
	$NJ=1;
} else {
	die $run_type;
}


my @nodes=@ARGV;

print "admixturePCAnj_dir: $admixturePCAnj_dir\n";
my $dir1="$admixturePCAnj_dir/1.admixture";
my $dir2="$admixturePCAnj_dir/2.pca";
my $dir3="$admixturePCAnj_dir/3.nj";

mkdir $admixturePCAnj_dir unless -e $admixturePCAnj_dir;

my $vcf_path="$admixturePCAnj_dir/$vcf";
my $ped="$vcf.ped";
my $ped_path="$admixturePCAnj_dir/$vcf.ped";
my $map="$vcf.map";
my $map_path="$admixturePCAnj_dir/$map";
my $vcftools_path="/data/00/software/vcftools/vcftools-vcftools-954e607/vcftools";
my $plink_path="/data/00/user/user153/software/LDBlockShow-1.36/bin/plink";
#my $admixture='/home/share/users/zhengzeyu2018/software/admixture_linux-1.3.0/admixture32';
my $admixture='/data/00/user/user153/software/dist/admixture_linux-1.3.0/admixture';


PREPARE:
my $prepare_result1=system("$vcftools_path --gzvcf $vcf_path --plink --out $vcf_path 2>&1") unless -e $ped_path;
print `date`;


#goto ADMIXTURE;
#goto PCA;
#goto NJ;
#goto THEEND;

goto ADMIXTURE if $ADMIXTURE;
goto PCA if $PCA;
goto NJ if $NJ;

ADMIXTURE:
print "\n** ADMIXTURE START\n";
mkdir $dir1 unless -e $dir1;

my $admixture_result1=system("$plink_path --noweb --ped $ped_path --map $map_path --recode 12 --out $dir1/$vcf.extract 2>&1") unless -e "$dir1/$vcf.extract.ped";

#my @admixture_result_files;
MCE::Loop::init {
max_workers => 1, chunk_size => 1
};
my @cmds;
my @admixture_result_files;
for (my $k=$admixture_min;$k<=$admixture_max;$k++){
	# print "** Now k=$k\n";
	my $cmd = "cd $dir1; $admixture --cv -j$admix_thread -B\\[100\\] $vcf.extract.ped $k > $vcf.extract.$k.log.out 2>&1";
	print "** will cal K=$k \n" and push @cmds, $cmd unless -e "$dir1/$vcf.extract.$k.Q";
	push @admixture_result_files, "$dir1/$vcf.extract.$k.Q";
}
#die join "\n", @cmds if @cmds;
zzRun(c=>\@cmds,t=>1,n=>\@nodes) if @cmds;
system("grep -h CV $dir1/*log.out > $dir1/BEST_K.txt");# unless -e "$dir1/BEST_K.txt";
my $ADMIXTURE_R = &PLOTADMIXTURE($dir1,@admixture_result_files);
system("Rscript $ADMIXTURE_R");
print "\n** ADMIXTURE done";
print `date`;
#exit;
goto THEEND if $ADMIXTURE;


PCA:
print "\n** PCA start.\n";
mkdir $dir2 unless -e $dir2;

my $map_map = &CHANGEMAP("$vcf_path.map");
# my $map_map="$vcf.map.map";
#my $map_map_path="$admixturePCAnj_dir/$map_map";
my $map_map_path="$map_map";
my $smartpac_perl='/data/00/software/EIG/EIG/bin/smartpca.perl';
#my $smartpac_perl='/home/share/users/wanglizhong2011/software/EIGENSOFT/EIG5.0.1/bin/smartpca.perl';
my $ind_path = &MAKE_IND($ped_path);
my $pca_result1=system("$smartpac_perl -i $ped_path -a $map_map_path -b $ind_path -o $dir2/2.$vcf.PCA -p $dir2/2.$vcf.PCA.plot -e $dir2/2.$vcf.PCA.eigenvalues -l $dir2/2.$vcf.PCA.log -m 0 -t 0") unless -e "$dir2/2.$vcf.PCA.evec";
my $pca_result2=&PLOT_PCA ("$dir2/2.$vcf.PCA.evec", "$ind_path");
my $pca_result3=system("Rscript $pca_result2");

print "\n** PCA done.\n";
print `date`;

goto THEEND if $PCA;

NJ:
print "\n** NJ start.\n";
print "\n** warning: long-name might cause ERROR: distance matrix is not symmetric:\n";
mkdir $dir3 unless -e $dir3;

my $NJ_result1=system("$plink_path --noweb --file $vcf_path --distance-matrix --out $dir3/$vcf") unless -e "$dir3/$vcf.mdist";
my $NJ_result2= &mdist2phylip( "$dir3/$vcf.mdist", "$ped_path", "$dir3/$vcf.phylip" );

my $nj_control_file_path="$dir3/$vcf.nj.control.txt";

print "NJ: \n";
system qq+cd $dir3; /home/share/software/phylip/phylip-3.696/exe/neighbor <<< '$vcf.phylip\nY\n' + unless -e "$dir3/$vcf.outtree";
rename("$dir3/outfile","$dir3/$vcf.outfile");
rename("$dir3/outtree","$dir3/$vcf.outtree");
print "\n** NJ done.\n";
print `date`;

goto THEEND if $NJ;


THEEND:
print "\n**ALL DONE\n";

sub PLOTADMIXTURE{
	my $dir=shift;
	my @file=@_;
	#my @file=`ls $dir/*.Q`;

	open(R,'>',"$dir/0.runR_Plot_admixture.r");
	print R qq|library("ggplot2")\n|;

	foreach my $file(@file){
		chomp $file;
		my $ped_path;
		my $prefix;
		my $suffix;
		if($file=~m/\/([^\/]+)\.(\d+)\.Q$/){
			$prefix="$1";
			$suffix=$2;
			$ped_path="$dir/$prefix.ped";
		}else{
			die "$file\n";
		}
		my @ind=&readPed($ped_path);
		my $out1="$dir/$prefix.$suffix.result";
		my $out2="$dir/$prefix.$suffix.result.ggplot2_data";
		open(O1,'>',"$out1");
		open(O2,'>',"$out2");
		open(F,$file);
		print O2 "id\tpercent\tk\n";
		my $i=0;
		while(<F>){
			chomp;
			my @a=split(/\s+/);
			for(my $j=0;$j<@a;$j++){
				print O2 "$ind[$i]\t$a[$j]\tk$j\n";
			}
			my $line=join "\t",@a;
			print O1 $ind[$i],"\t","$line\n";
			$i++;
		}
		close(F);
		close(O2);
		close(O1);
		print R qq|
		a=read.table("$out2",header=T)
		pdf(file="$dir/$prefix.$suffix.pdf",width=30,height=7)
		ggplot(a,aes(x=id,y=percent))+geom_bar(stat="identity",aes(fill=k),width=1)+theme(axis.text.x=element_text(angle = 90, hjust = 1))
		dev.off()
		|;

		print "$file PLOTADMIXTURE_prepare_complete\n";
	}
	close(R);
	return "$dir/0.runR_Plot_admixture.r";
}



sub readPed{
	my $file=shift;
	chomp $file;
	my @r;
	open(F,$file) || die "$!\n";
	while(<F>){
		chomp;
		if(/^(\S+)/){
			push @r,$1;
		}
	}
	close(F);
	return @r;
}



sub CHANGEMAP{
	my ($map)=@_;
	my $new="$map.map";
	return $new if -s $new;
	open(O,'>',$new);
	open(F,$map);
	my $window=1000000; # 1M
	my $count=0;
	my ($prescaffold,$presite);
	my ($start,$end);
	while(<F>){
		chomp;
		my @a=split("\t",$_);
		$a[0]=1;
		if($count==0){
			($prescaffold,$presite)=split(":",$a[1]);
			$a[1]="rss".$a[3];
			print O join("\t",@a),"\n";
			$count++;
		}else{
			my ($scaffold,$site)=split(":",$a[1]);
			if($scaffold eq $prescaffold){
				if($count==1){
					$presite=$site;
				}else{
					$a[3]+=$start;
					$presite=$a[3];
				}
			}else{
				$count++;
				$prescaffold=$scaffold;
				$start=$presite+$window;
				$a[3]+=$start;
				$presite=$a[3];
			}
			$a[1]="rss".$a[3];
			print O join("\t",@a),"\n";
		}
	}

	close F;
	close O;
	return "$map.map";
}


sub MAKE_IND{
	my $ped=shift;
	my $out=$ped.".ind";
	return $out if -s $out;
	my $count=0;
	open(O,'>'."$out");
	open(F,$ped);
	while(<F>){
		chomp;
		my @a=split(/\s+/);
		#my @b=split(//,$a[1]);
		my $species_now;
		$species_now = $a[1]=~/^([a-zA-Z_\-]+)/ ? $1 : 'unknown';
		my $ind="$a[1]";
		$count++;
		print O "$count\t$ind\t0\t0\t0\t$species_now\n";
	}
	close(F);
	close(O);
	return $out;
}



sub PLOT_PCA{
	my $evec=shift or die "perl $0 \$evec \$ind\n";
	my %ind2sp;
	my %ind2id;

	my $ind=shift or die "perl $0 \$evec \$ind\n";
open (F_ind,"$ind");
while (<F_ind>) {
	chomp;
	my @a=split(/\s+/,$_);
	# 1       CDM01   0       0       0       CDM
	# a0        a1                             a5
	my $species_now;
	$species_now = $a[1]=~/^([a-zA-Z_\-]+)/ ? $1 : 'unknown';
	$ind2sp{$a[0]}=$species_now;
	$ind2id{$a[0]}=$a[1];
}
close F_ind;
open (F_evec,"<$evec")||die"$evec not found!: $!";
open (O_data,">$evec.ggplot2_data");
while (<F_evec>) {
	chomp;
	s/^\s+//;
	my @a=split(/\s+/,$_);
	if (/^#eigvals/){
		my @say = ('FID');
		push @say, "PC$_" foreach (1..@a-1);
		push @say, qw/species ID/;
		say  O_data join "\t", @say;
		#print O_data "FID\tPC1\tPC2\tPC3\tPC4\tPC5\tPC6\tPC7\tPC8\tPC9\tPC10\tspecies\tID\n";
	}else{
		#$a[0]=~/\d+\:([a-zA-Z]+)/ or die "$_\n";
		#$a[-1]=$1;
		$a[-1]=$ind2sp{$a[0]};
		push ( @a,$ind2id{$a[0]} );
		print O_data join("\t",@a),"\n";
	}
}
close F_evec;
close O_data;

open (O_R,">$evec.R");
print O_R qq|library("ggplot2");\n|;
print O_R qq|a=read.table("$evec.ggplot2_data",header=T);\n\n|;
for (my $i=1;$i<=3;$i++){
	for (my $j=$i+1;$j<=4;$j++){
		print O_R qq|pdf(file="$evec.PC${i}_PC${j}.pdf");\n|;
		print O_R qq|ggplot(a,aes(PC$i,PC$j,color=species))+geom_point(alpha=0.8,size=4)\n|;
		print O_R qq|dev.off()\n\n|;
	}
}
close O_R;

return "$evec.R";
}


sub readid{
	my $file=shift;
	my @a;
	open(F,$file);
	while(<F>){
		chomp;
		if(/^([a-zA-Z0-9_\-]+)/){
			push @a,$1;
		}

	}
	close(F);
	#  print "\t",scalar(@a),"\n";
	return @a;
}


sub mdist2phylip{
	my ($mdist_path,$ped_path,$out_path)=@_;
	my @id_all=&readid($ped_path);

	open(O,'>',$out_path);
	print O "\t",scalar(@id_all),"\n";
	my $i=0;
	open(F,$mdist_path);
	while(<F>){
		chomp;
		my $len=length($id_all[$i]);
		my $x=10-$len;
		my $a=" " x $x;
		print O "$id_all[$i]","$a\t$_\n";
		$i++;
	}
	close(F);
	close(O);
}




