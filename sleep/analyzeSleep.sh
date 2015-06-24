#!/bin/sh
#$ -N sleep
#$ -S /bin/sh
#$ -j y
#$ -q short.q
#$ -o /data2/projects/btmn/analysis/amb/logs/sleep.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzeSleep('$1'); catch; end; quit"