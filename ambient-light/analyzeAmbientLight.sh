#!/bin/sh
#$ -N ambientLight
#$ -S /bin/sh
#$ -j y
#$ -q veryshort.q
#$ -o /data2/projects/btmn/analysis/amb/logs/ambientLight.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzeAmbientLight('$1'); catch; end; quit"