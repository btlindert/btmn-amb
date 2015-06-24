#!/bin/sh
#$ -N irTemperature
#$ -S /bin/sh
#$ -j y
#$ -q veryshort.q
#$ -o /data2/projects/btmn/analysis/amb/irTemperature.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzePhilipsIr'$1'); catch; end; quit"