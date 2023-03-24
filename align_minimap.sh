#!/bin/bash
#SBATCH --time=15:00:00 #e.g. 24:00:00, 1-13:00:00
#SBATCH --job-name=fq-minimap+samtools-bam+csi
#SBATCH --mem=45G #e.g. 100G
#SBATCH --account=def-jfu
#SBATCH --cpus-per-task=32
#SBATCH --mail-type=All #Valid type values are NONE, BEGIN, END, FAIL, REQUEUE, ALL (equivalent to BEGIN, END, FAIL, INVALID_DEPEND, REQUEUE, and STAGE_OUT), INVALID_DEPEND (dependency never satisfied), STAGE_OUT (burst buffer stage out and teardown completed), TIME_LIMIT, TIME_LIMIT_90 (reached 90 percent of time limit), TIME_LIMIT_80 (reached 80 percent of time limit), TIME_LIMIT_50 (reached 50 percent of time limit) and ARRAY_TASKS (send emails for each array task).
#SBATCH --mail-user=rliu13@uoguelph.ca
#SBATCH --array=1-12 #e.g.--array=0,6,16-32, --array=0-15:4 (equivalent to --array=0,4,8,12), --array=0-15%4 (limit number of simultaneously running jobs) 
#set -xv

start_time=`date --date='0 days ago' "+%Y-%m-%d %H:%M:%S"`

cd /home/maxine91/scratch/divided_minimap.dir
module load StdEnv/2020 minimap2/2.24 samtools/1.16.1


echo "Starting task $SLURM_ARRAY_TASK_ID"
sample_name=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_list)
echo "Working directory is $(pwd), the sample name is $sample_name"


minimap2 -R @RG\\tID:Pacbio2022\\tSM:$sample_name \
    -t 30 -2 -I 5g -ax map-pb \
    /home/maxine91/projects/def-jfu/data/bufo_genome/dividedNCBIgenome.fna \
    /home/maxine91/projects/def-jfu/data/Z03_fq.dir/$sample_name.fq \
    > alndivided.$sample_name.sam

if [ $? -eq 0 ]; then
  echo "Alignment succeed!"
else
  echo "Alignment failed."
  exit
fi

samtools view -@ 31 -b alndivided.$sample_name.sam > alndivided.$sample_name.bam
#Number of BAM compression threads to use in addition to main thread [0].
if [ $? -eq 0 ]; then
  echo "Converting sam to bam succeed!"
else
  echo "Converting sam to bam failed."
  exit
fi

samtools sort -m 1100M -@ 31 /home/maxine91/projects/def-jfu/results/divided_minimap.dir/alndivided.$sample_name.bam -o divsorted.$sample_name.bam
# -m :Approximately the maximum required memory per thread, specified either in bytes or with a K, M, or G suffix. [768 MiB]
# To prevent sort from creating a huge number of temporary files, it enforces a minimum value of 1M for this setting.
# -@ INT: Set number of sorting and compression threads. By default, operation is single-threaded.

if [ $? -eq 0 ]; then
  echo "Sorting succeed!"
else
  echo "Sorting failed."
  exit
fi

samtools index -@ 31 divsorted.$sample_name.bam

if [ $? -eq 0 ]; then
  echo "Indexing succeed!"
else
  echo "Indexing failed."
  exit
fi

finish_time=`date --date='0 days ago' "+%Y-%m-%d %H:%M:%S"`
duration=$(($(($(date +%s -d "$finish_time")-$(date +%s -d "$start_time")))))
dhours=`echo "scale=5;a=$duration/3600;if(length(a)==scale(a)) print 0;print a"|bc`

echo "this shell script execution duration: $duration sec"
echo "this shell script execution duration: $dhours hours"

