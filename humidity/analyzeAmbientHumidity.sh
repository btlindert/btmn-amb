#!/bin/sh
#$ -N ambientHumidity
#$ -S /bin/sh
#$ -j y
#$ -q veryshort.q
#$ -o /data2/projects/btmn/analysis/amb/ambientHumidity.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzeAmbientHumidity('$1'); catch; end; quit"