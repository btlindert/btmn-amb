#!/bin/sh
#$ -N ambientTemperature
#$ -S /bin/sh
#$ -j y
#$ -q veryshort.q
#$ -o /data2/projects/btmn/analysis/amb/logs/ambientTemperature.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzeAmbientTemperature('$1'); catch; end; quit"