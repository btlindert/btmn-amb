#!/bin/sh
#$ -N posture
#$ -S /bin/sh
#$ -j y
#$ -q long.q
#$ -o /data2/projects/btmn/analysis/amb/logs/posture.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzePosture('$1'); catch; end; quit"