#!/bin/env perl
use warnings;
use strict;
use Getopt::Long;
#use File::Basename;
sub usage{
    print STDERR <<USAGE;
    ################################################
            Version 1.0 by Wing-L   2013.04.03

      Usage: $0 <qsub_jobs_shell> [option] >STDOUT

      Advanced:
        -l <int>: set number of lines per child job.[1]
        -m <int>: set max job number to qsub in this program.[100]
        -u <int>: set max limited jobs for a user.[750]
        -v <flo>: set the memory(G) to qsub.[1](G)
        -q <str>: set the queue name for qsub.[' -q st.q']
        -p <str>: set the project name for qsub.[' -P st_plant']
        -o <str>: set other command in qsub.[none]
        -j <str>: set prefix of job script.[job]
        -t <int>: set check time intervals.[300](s)
        -r      : reqsub the job until all jobs finished.[1]
        -a <str>: convert the filename in shell to absolute path.[yes]
        -c <str>: continue unfinished jobs by qsub dir, default=no.

      eg: perl $0 qsub.sh -l 1 -m 50 -v 0.2 -o \" -l h=compute-0-10\" -r
       reqsub:
          perl $0 qsub.sh -r work_shell.sh.150989.qsub
    ################################################
USAGE
    exit;
}

############# global variable
my ($line_per_job, $max_throw_num, $max_user_job_num, $mem_per_job, $queue_name, $project_name, $other_command, $job_prefix, $check_time, $reqsub_job, $convert_abspath, $continue_jobs, $qsub_sge_resource);

GetOptions(
  "l|lines=i"=>\$line_per_job,
  "m|maxjob=i"=>\$max_throw_num,
  "u=i"=>\$max_user_job_num,
  "v=f"=>\$mem_per_job,
  "q|queue=s"=>\$queue_name,
  "p|pro_code=s"=>\$project_name,
  "o=s"=>\$other_command,
  "j=s"=>\$job_prefix,
  "t|interval=i"=>\$check_time,
  "r|reqsub"=>\$reqsub_job,
  "a|convert=s"=>\$convert_abspath,
  "c=s"=>\$continue_jobs,
  "resource=s"=>\$qsub_sge_resource,
#  ""=>\,
);

&usage if(@ARGV !=1);
my ($origin_job_shell)=@ARGV;
$|=1;

$line_per_job ||=1;
$max_throw_num ||=100;
$max_user_job_num ||=750;
$mem_per_job ||=1;
$queue_name ||= '-q st.q';
$project_name ||= '';
$other_command ||='';
$job_prefix ||='job';
$check_time ||=300;
$reqsub_job=1 unless(defined $reqsub_job);
$convert_abspath ||='yes';
$continue_jobs ||='';

############ Internal const value
my $MAX_REQSUB_CIRCLE = 10;
my $FINISH_MARK = 'The-Work-is-completed!';
my $FIN_TEXT = "\necho \"$FINISH_MARK\"\n";

my $st_num = '000001';
my $pwd = `pwd`;chomp $pwd;
my $user = `whoami`;chomp $user;
my $shell_base_name = `basename $origin_job_shell `;chomp $shell_base_name;
`ln -s $origin_job_shell "$pwd/$shell_base_name" ` if($shell_base_name ne $origin_job_shell and !-e $shell_base_name);
my $qsub_dir   = "$pwd/$shell_base_name.$$.qsub";
my $log_file   = "$pwd/$shell_base_name.$$.log";
my $kill_file  = "$pwd/$shell_base_name.$$.kill.sh";
my $clean_file = "$pwd/$shell_base_name.$$.clean.sh";
my $qsub_command = "qsub -cwd -l vf=${mem_per_job}G $queue_name $project_name $other_command";
############################  BEGIN MAIN  ############################
die("already exist $shell_base_name.$$.qsub\n") if(-e "$shell_base_name.$$.qsub");
die("-l lines per child job: $line_per_job must >=1\n") if($line_per_job <1);


open LOG,">$log_file" or die("$!:$log_file\n");
open KILL,">$kill_file" or die("$!:$kill_file\n");
open CLEAN,">$clean_file" or die("$!:$clean_file\n");

print KILL  "kill $$\n";


######## choose mode
if(!$continue_jobs){
    mkdir $qsub_dir;
    print CLEAN "rm -r $qsub_dir $log_file $kill_file $clean_file 2>/dev/null\n";
    my @jobs;
    &Split_script(\@jobs);
    &main_cycle(\@jobs);
}else{
    my @jobs;
    $qsub_dir = $continue_jobs;
    print CLEAN "rm -r $qsub_dir $log_file $kill_file $clean_file 2>/dev/null\n";
    &get_unfinished(\@jobs);
    &main_cycle(\@jobs);
}



###### qsub jobs and check
sub main_cycle{
    my $jobs_p = shift;
    my $total_jobs = 0;
    my $running_jobs = 0;
    my %qsubed_jobs;
    while(1){
        my $qsub_number = 0;
        ($total_jobs, $running_jobs) = &job_stat(\%qsubed_jobs);
        ############## if jobs_number allowed, qsub jobs
        if($running_jobs < $max_throw_num and $total_jobs < $max_user_job_num){
            $qsub_number = $max_throw_num-$running_jobs < $max_user_job_num-$total_jobs ? $max_throw_num-$running_jobs : $max_user_job_num-$total_jobs;
            my $remain_jobs = &qsub_jobs($qsub_number, $jobs_p, \%qsubed_jobs);
            ########## break the cycle if all jobs finished.
            if($remain_jobs==0){
                print LOG "All finished at ";print LOG &GetTime();
                exit 0;
            }
        }
        sleep($check_time);
    }
    return 0;
}
############################   END  MAIN  ############################

###############  Function  ###############
##################
# Read the shell script file and split
# &Split_script(\@arr_for_job_address_and_stat);
##################
sub Split_script{
    my $job_arr_p = shift;
    my $script_text;
    open IN,"<$shell_base_name" or die("$!:$shell_base_name\n");
    while(my $line=<IN>){
        my @info=(split /\s+/,$line);
        &convert_abs_path(\$line) if($convert_abspath eq 'yes');
        $script_text.=$line;
        if($. % $line_per_job==0 or eof(IN)){
            open SH,">$qsub_dir/${job_prefix}_$st_num.sh" or die("$!:$qsub_dir/${job_prefix}_$st_num.sh\n");
            print SH $script_text;
            print SH $FIN_TEXT;
            push @{$job_arr_p},["${job_prefix}_$st_num.sh",'prepare'];
            $script_text = '';
            $st_num++;
            close SH;
        }
    }
    close IN;
    return 0;
}

##################
# covert the relative path to the absolute path.
# $abs_path=&convert_abs_path(\$relative_path);
##################
sub convert_abs_path{
    my $text_p = shift;
    my @split_part = split /\s+/,${$text_p};
    foreach my $e (@split_part){
        next if($e=~/^\//);
        if($e=~/^[\d\&]?>+/ and substr($',0,1) ne '/'){### For >../a.txt 2>../err.txt >>../add.txt &>xx.txt
            next unless($`);
            $e = "$& $pwd/$'";
        }elsif(-e "$e" or $e=~/^(\.+|\w+)\//){### For exist.log ./jj.log ../old.log pwd/output.log
            $e = "$pwd/$e";
        }
    }
    ${$text_p}=join (' ',@split_part)."\n";
    return 0;
}

##################
# stat the job condition
# ($total_job_number,$running_job_number)=&job_stat(\%qsubed_job_hash);
##################
sub job_stat{
    my $job_hash = shift;
    my $total_job_number = 0;
    my $running_job_number = 0;
    my %total_jobs;
    foreach my $e (split /\n+/,`qstat -u $user | sed 1,2d `){
        $e=~s/^\s+//;
        #next if($e=~/^\D/);
        my ($id, $stat) = (split /\s+/,$e)[0,4];
        $total_jobs{$id} = $stat;
    }
    $total_job_number = keys %total_jobs;
    foreach my $e (keys %{$job_hash}){
        if(defined $total_jobs{$e}){
            if($total_jobs{$e}=~/d|Eqw/i){
                `qdel $e `;
                ${$job_hash}{$e}[1] = 'error';
                print LOG "Death, job $e, ${$job_hash}{$e}[0] , ";print LOG &GetTime();
                delete ${$job_hash}{$e};
            }else{
                $running_job_number++;
            }
        }else{
            &check_finish($e, ${$job_hash}{$e});
            delete ${$job_hash}{$e};
        }
    }
    return ($total_job_number, $running_job_number);
}

##################
# qsub the jobs
# $unfinish_job_number=&qsub_jobs($qsub_number,\@jobs_address_and_stat,\%qsubed_jobs);
##################
sub qsub_jobs{
    my ($number, $job_arr_p, $list_p)=@_;
    my $remain = 0;
    chdir $qsub_dir;
    foreach my $e (@{$job_arr_p}){
        $remain++ if($e->[1] ne 'finished');
        $remain-- if($e->[1] eq 'error' and $reqsub_job!=1);
        if($number>0 and ($e->[1] eq 'prepare' or ($e->[1] eq 'error' and $reqsub_job==1))){
            my $qsub_info = `$qsub_command $e->[0] `;
            $qsub_info=~/Your job (\d+)/;
            ${$list_p}{$1} = $e;
            print KILL "qdel $1 &>/dev/null # $e->[1] --> running, $e->[0]\n";
            my $type = $e->[1] eq 'error' ? 'reqsub' : 'qsub';
            print LOG "$type, $e->[1] --> running, $e->[0] , ";print LOG &GetTime();
            $e->[1] = 'running';
            $number--;
        }
    }
    chdir $pwd;
    return $remain;
}
##################
# Check whether the jobs are finished, change the stat
# &check_finish($job_id,$point_in_jobs_arr);
##################
sub check_finish{
    my ($id, $address_p) = @_;
    my $mark_line = '';
    $mark_line = `tail -1 "$qsub_dir/$address_p->[0].o$id"` if(-e "$qsub_dir/$address_p->[0].o$id");
    if($mark_line=~/$FINISH_MARK/){
        $address_p->[1] = 'finished';
        print LOG "finished, job $id, $address_p->[0] , ";print LOG &GetTime();
    }else{
        $address_p->[1] = 'error';
        print LOG "error, job $id, $address_p->[0] , ";print LOG &GetTime();
    }
    return 0;
}

##################
# Get unfinished jobs in qsub_dir,and delete the *.e* *.o* file.
# &get_unfinished(\@jobs);
##################
sub get_unfinished{
    my $job_arr_p = shift;
    my $unfinished_number = 0;
    foreach my $e (glob "$qsub_dir/*.sh"){
        my $base = `basename $e `;
        chomp $base;
        my $text = `cat $e.o* 2>/dev/null `;
        if($text=~/The-Work-is-completed!/){
            print LOG "finished $base\n";
        }else{
            `rm "$e.*" 2>/dev/null `;
            push @{$job_arr_p},["$base",'prepare'];
            print LOG "restart $base\n";
            $unfinished_number++;
        }
    }
    if($unfinished_number==0){
        print LOG "All jobs were finished!\n";
        exit 0;
    }
    return 0;
}

##################
# print local time
# &GetTime();
##################
sub GetTime{
    my $this_time = localtime;
    return $this_time."\n";
}
################## God's in his heaven, All's right with the world. ##################
