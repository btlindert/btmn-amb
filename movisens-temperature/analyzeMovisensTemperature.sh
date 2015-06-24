#!/bin/sh
#$ -N movisensTemperature
#$ -S /bin/sh
#$ -j y
#$ -q long.q
#$ -o /data2/projects/btmn/analysis/amb/logs/movisensTemperature.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzeMovisensTemperature('$1'); catch; end; quit"