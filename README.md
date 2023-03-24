# before_svcalling
 Everything before sv calling. From raw data to sorted aligned bam. 

## align_minimap.sh
It's to align long-read sequence data in fq format to reference genome using minimap2. Then sort and index.

INPUT: sample_list, genome.fna, sample.fq

OUTPUT: sorted.sample.bam, .bam.bai

SIZE of INPUT: genome.fna 4.36G; sample.fq 262G
 
CPU: 32

Memory: 38 GB

Time: 13 hours
