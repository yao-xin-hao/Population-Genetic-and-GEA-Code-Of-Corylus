#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use v5.16;
use Getopt::Long;
use Getopt::Std;
#use Cwd 'abs_path';
use zzRun;
use zzIO;
use File::Spec;

sub help() {
    die "usage: perl x.pl [options] [node1 node2 ...]
    Options: -h      help
            [-t INT] threads (default=16)
             -l FILE input fq file list, files in list must be xxx_1.trim.fq.gz or xxx_1.fq.gz
             -o DIR  output 02.map dir
             -R FILE ref_file.fa
            [-T DIR] temp file dir (default=/tmp)
            [-K INT] keep unmaped reads? 0 or 1, default 1 
            -f       Force run, without check exists bam and GCstat file
            [-A]     Do not remove PCR-dup
             \n";
}

my $skip_IndelRealigner = 1;
my $PRINT_FINAL_BAM=1;
my $keep_non_map_reads=1;

&help() if (@ARGV < 1);
my %opts = (h=>undef, t=>16, l=>undef, o=>undef, T=>'/tmp', R=>undef, K=>1, f=>undef, A=>undef);
getopts('ht:l:o:T:R:fA', \%opts);

$keep_non_map_reads = $opts{K};

my @nodes=();
my $thread_per_node=$opts{t};
@nodes = @ARGV if @ARGV;

&help() if ( $opts{h} || !$opts{l} || !$opts{o} || !$opts{R} );

my $force = $opts{f} ? 1 : 0; # f: force run
my $rm_pcr_dup = $opts{A} ? 0 : 1; # A: Do not remove PCR-dup
my $ref = File::Spec->rel2abs($opts{R});
my $max_thread=$opts{t};
my $temp_dir= File::Spec->rel2abs($opts{T});
my $map_dir = File::Spec->rel2abs($opts{o});


if (! -e "$ref.sa") {
    say STDERR "ref not indexed, trying bwa index";
    system("bwa index $ref");
}

if (! -e $map_dir) {
    say STDERR "output dir not existes, try to create: $map_dir";
    mkdir $map_dir or die "Failed!! $!";
}else {
    say STDERR "output dir is: $map_dir";
}

print STDERR "\n** Now in Node: ";
print STDERR `hostname`;



my $bwa = '/data/00/software/bwa/bwa-0.7.17/bwa';
#my $samtools='/data/00/software/samtools/samtools-1.10/samtools';
my $sambamba = '/data/00/software/sambamba/sambamba-0.8.0-linux-amd64-static';
my $ref_cal_N_count_pl='/data/00/user/user101/script/99.other/ref_cal_N_count.pl';
my $cal_GC_script='perl /data/00/user/user101/script/02.alignment/1.1.cal_GC.pl';
my $samblaster = '/data/00/software/bamblaster/samblaster-v.0.1.26/samblaster';

my $gemone_size=&get_gemone_size();
say STDERR "Genome size : $gemone_size ";

my %list=&readList($opts{l});

mkdir $_ or die "$_ not exists and failed to create !" foreach grep{!-e$_} ($map_dir, $temp_dir);


RUN:
print STDERR `date`;
print STDERR "\n";
print STDERR "start bwa mem";
print STDERR "\n";
my @cmds=();
foreach my $id (sort keys %list){
    #say STDERR $id;
    my $read1=$list{$id}{'fq1'};
    my $read2;
    my $samblaster_append = '';
    if (exists $list{$id}{'fq2'}) {
        $read2 = $list{$id}{'fq2'};
    } else {
        $read2 = '';
        $samblaster_append .= ' --ignoreUnmated ';
    }
    #die  "$id\t$read1\t$read2\n" unless ( -e $read1 &&  -e $read2);
    my $log = "$map_dir/$id.dedup.bam.log";
    my $out_bam = "$map_dir/$id.dedup.bam";
    my $out_bam_GC = "$map_dir/$id.dedup.bam.GCstat";
    #`date >> $log`;
    $samblaster_append .= " -r " if $keep_non_map_reads == 1;
    my $bwa_cmd="$bwa mem -t $thread_per_node -M -R \'\@RG\\tID:$id\\tPL:illumina\\tPU:illumina\\tLB:$id\\tSM:$id\' $ref $read1 $read2 2>> $log";
    my $rmpcr_cmd = "$samblaster $samblaster_append -M 2>> $log";
    my $sort_cmd = "$sambamba view -S -h -f bam -o /dev/stdout -l 0 /dev/stdin | $sambamba sort -m 10G -o $out_bam --tmpdir $temp_dir/$id /dev/stdin -t 8 2>> $log";
    my $cmd;
    if ($rm_pcr_dup) {
        $cmd = "$bwa_cmd | $rmpcr_cmd | $sort_cmd";
    } else { # not rm PCR dup
        $cmd = "$bwa_cmd | $sort_cmd";
    }
# samtools view -f xxxxx
#2(0x2)		PROPER_PAIR		代表这个序列和参考序列完全匹配，没有插入缺失
#4(0x4)		UNMAP	代表这个序列没有mapping到参考序列上
    next if (&check_GC_isOK($out_bam_GC, $id)==1 and $force==0);
    my $GC_cmd = "$cal_GC_script $out_bam $out_bam_GC $gemone_size";
    if (-e $out_bam and -s $out_bam>1024*1024*1024) { # 1G
        $cmd = $GC_cmd;
    } else {
        $cmd = "$cmd ; $GC_cmd";
    }
    `rm -fr $temp_dir/$id*`;
    push @cmds, $cmd;
    #say STDERR $id;
}
#die join "\n", @cmds;
#&zzRun(t=>$thread_per_node, m=>"32G",c=>\@cmds, p=>" -s 4") if @cmds;
say $_ foreach @cmds;
@cmds=();

print STDERR 'bwa - sort - markdup done'."\n";
print STDERR `date`;
print STDERR "\n";



GEN_LIST:
my @FINAL_BAM;
push @FINAL_BAM, "$map_dir/$_.dedup.bam" foreach sort keys %list;
say STDERR join "\n", @FINAL_BAM if $PRINT_FINAL_BAM;
my $temp_file = "${map_dir}.maped.list";
$temp_file .= '.1' while -e $temp_file;
`echo '$_' >> $temp_file` foreach @FINAL_BAM;

exit;


sub check_GC_isOK {
    my ($GCfile, $id) = @_;
    if (-s $GCfile and system("grep '$id' $GCfile >/dev/null 2>&1")==0) {
        return 1;
    }
    return 0;
}


sub readList {
    my @file_list;
    #open (my $L," < $_[0]") or die "can't open list: $_[0] ! $!";
    my $L = open_in_fh($_[0]);
    while (<$L>) {
        chomp;
        next if ( ! $_ || /^#/);
        # die "??! $_  not " . '/_[12].(fq|fastq)(.gz)?$/' . "\n" unless /_[12]\.(trim\.)?(fq|fastq)(\.gz)?$/;
        push (@file_list, $_);
    }
    close $L;

    print STDERR "input files are: \n";
    &print_list( @file_list );
    print STDERR "\n";
    my %r;
    foreach my $bam (@file_list) {
        #next if /_2.trim\.fq(\.gz)?$/;
        chomp $bam;
        my ($fq1,$fq2,$lan);
        my $base = basename $bam;
        $base =~ /^([^_]+).*?[_.]([12])(\.trim|\.clean)?\.(fq|fastq)(\.gz)?$/ or die "!!can't:: $bam not xx/2.trim/xx_[12].(trim.)?fq(.gz)?\n";
        my ($id, $i) = ($1, $2);
        $id = $opts{$i} if defined $opts{i};
        $r{$id}{"fq$i"}=$bam;
        #$r{$2}{'fq2'}="${1}_2.trim.fq.gz";
        #die "??? $_ ??? $r{$2}{'fq1'} not exist\n" unless -e $r{$2}{'fq1'};
        #die "??? $_ ??? $r{$2}{'fq2'} not exist\n" unless -e $r{$2}{'fq2'};
    }
    foreach my $id(keys %r) {
        my $count = scalar(keys $r{$id}->%*);
        die "${id}_1 not in list" if ! exists $r{$id}{fq1};
        die "${id}_1 not exists, $r{$id}{fq1}" if ! -e $r{$id}{fq1};
        if ($count==1) {
            say STDERR "WARN! $id has only 1 read file! treated as single-end";
            #$r{$id}{fq2} = dirname($r{$id}{fq1})."/${id}_2.trim.fq.gz" if ! exists $r{$id}{fq2};
            # pass
        } elsif ($count==2) {
            die "${id}_2 not in list" if ! exists $r{$id}{fq2};
            die "${id}_2 not exists, $r{$id}{fq2}" if ! -e $r{$id}{fq2};
        } else {
            die "Error: $id in list error";
        }
    }
    return %r;
}

sub print_list {
    my @list=@_;
    for (@list){
        print STDERR "$_\n";
    }
}



sub get_gemone_size {
    my $t = `perl $ref_cal_N_count_pl -i $ref -q`;
    #die "perl $ref_cal_N_count_pl $ref 1>/dev/null 2>&1";
    say STDERR "genome size ori: $t";
    chomp $t;
    $t=~/^(\d+)-(\d+)$/;
    return ($1-$2);
}
