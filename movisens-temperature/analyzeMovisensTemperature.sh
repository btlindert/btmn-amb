#!/bin/sh
#$ -N movisensTemperature
#$ -S /bin/sh
#$ -j y
#$ -q long.q
#$ -o /data2/projects/btmn/analysis/amb/movisensTemperature.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try movisensTemperature('$1'); catch; end; quit"