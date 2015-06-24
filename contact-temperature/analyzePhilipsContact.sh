#!/bin/sh
#$ -N contactTemperature
#$ -S /bin/sh
#$ -j y
#$ -q veryshort.q
#$ -o /data2/projects/btmn/analysis/amb/logs/contactTemperature.log
#$ -u blindert
matlab -nodesktop -nosplash -nodisplay -r "try analyzePhilipsContact('$1'); catch; end; quit"