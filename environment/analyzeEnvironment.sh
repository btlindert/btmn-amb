#!/bin/bash
#$ -N environment
#$ -S /bin/bash
#$ -q regular.q
#$ -o /someren/projects/btmn/analysis/amb/environment/logs/$JOB_NAME_$JOB_ID.o
#$ -e /someren/projects/btmn/analysis/amb/environment/logs/$JOB_NAME_$JOB_ID.e
#$ -j y
#$ -u lindert

# Echo some info to the output file
/bin/echo Hostname: `hostname`
/bin/echo Start time: `date`
/bin/echo Subject: $1
/bin/echo Date: $2

# Load environment modules and matlab
/bin/echo Loading environment modules...
. /etc/profile.d/modules.sh
/bin/echo Loading matlab module...
module load matlab/r2014a

# Run the matlab job
/bin/echo Starting matlab...
matlab -nodesktop -nosplash -nodisplay -r "addpath(genpath('/someren/projects/btmn/scripts/btmn-amb/')); analyzeEnvironment('$1','$2'); quit"

# End
/bin/echo End time: `date`
