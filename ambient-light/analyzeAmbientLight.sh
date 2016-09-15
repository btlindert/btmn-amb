#!/bin/bash
#$ -N ambientLight
#$ -S /bin/bash
#$ -j y
#$ -q veryshort.q
#$ -o /someren/projects/btmn/analysis/amb/ambient-light/logs/$JOB_NAME.o$JOB_ID
#$ -e /someren/projects/btmn/analysis/amb/ambient-light/logs/$JOB_NAME.e$JOB_ID
#$ -u lindert

# Load environment modules and matlab
. /etc/profile.d/modules.sh
module load matlab/r2014a

# Run the matlab job
matlab -nodesktop -nosplash -nodisplay -r "addpath(genpath('/someren/projects/btmn/scripts/btmn-amb/')); try analyzeAmbientLight('$1'); catch; disp('fail');  end; quit"
