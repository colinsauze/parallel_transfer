#!/bin/bash

backend=SGE

echo "How many groups do you want?"

read num_groups

echo "What is the source directory?"

read src_dir

echo "What is the destination path (username@hostname:directory)?"

read dst_dir

./create_file_groups $num_groups

if [ "$backend" = "SGE" ] ; then

    #SGE version

    sge_file="parallel_transfer.sge"

    echo "#$ -S /bin/bash" > $sge_file
    echo "#$ -N parallel_transfer" >> $sge_file
    echo "#$ -j y" >> $sge_file
    echo "#$ -cwd" >> $sge_file
    echo "#$ -m e" >> $sge_file
    echo "#$ -l h_vmem=1G" >> $sge_file
    echo "filename=group_\$[\$SGE_TASK_ID-1]" >> $sge_file
    echo "echo \"task \$SGE_TASK_ID copying files from \$filename\"" >> $sge_file
    echo "echo \"sleeping for \$[\$SGE_TASK_ID*15] seconds\"" >> $sge_file
    echo "sleep \$[\$SGE_TASK_ID*15]" >> $sge_file
    echo "echo \"Starting rsync\"" >> $sge_file
    echo "rsync -ave ssh --files-from=\$filename $src_dir $dst_dir" >> $sge_file

    qsub -t 1-$num_groups $sge_file

elif [ "$backend" = "Slurm" ] ; then

    #Slurm version

    slurm_file="parallel_transfer.slurm"

    echo "#!/bin/bash --login" > $slurm_file
    echo "###" >> $slurm_file
    echo "#SBATCH --job-name=parallel_transfer" >> $slurm_file
    echo "#SBATCH --output=parallel_transfer.out.%J-%A" >> $slurm_file
    echo "#SBATCH --error=parallel_transfer.err.%J-%A" >> $slurm_file
    echo "###" >> $slurm_file
    echo "filename=group_\$[\$SLURM_TASK_ID-1]" >> $slurm_file
    echo "echo \"task \$SLURM_TASK_ID copying files from \$filename\"" >> $slurm_file
    echo "echo \"sleeping for \$[\$SLURM_TASK_ID*15] seconds\"" >> $slurm_file
    echo "sleep \$[\$SLURM_TASK_ID*15]" >> $slurm_file
    echo "echo \"Starting rsync\"" >> $slurm_file
    echo "rsync -ave ssh --files-from=\$filename $src_dir $dst_dir" >> $slurm_file

    sbatch --array=1-$num_groups $slurm_file

elif [ "$backend" = "Parallel" ] ; then

    #GNU Parallel version
    ls group_* | parallel -j $num_groups --joblog=rsync_jobs --delay=15 "rsync -ave ssh --files-from={} $src_dir $dst_dir"

else 

    echo "Unknown backed $backend"

fi


# cleanup with a final rsync
echo "When the job is complete run a manual rsync to cleanup any files which might have been missed"
echo "rsync -ave ssh $src_dir $dst_dir"
