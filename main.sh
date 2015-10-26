#! /bin/sh

# Folder specification.
baseFolder="/data2/projects/btmn/analysis/amb"
modality=("ambient-humidity" 
"ambient-light" 
"ambient-temperature" 
"baro-pressure"
"contact-temperature" 
"movisens-temperature" 
"activity" 
"posture" 
"sleep")
modality=("sleep")

scriptName=("analyzeAmbientHumidity" 
"analyzeAmbientLight" 
"analyzeAmbientTemperature"
"analyzeBaroPressure" 
"analyzePhilipsContact" 
"analyzeMovisensTemperature" 
"analyzeActivity" 
"analyzePosture" 
"analyzeSleep")
scriptName=("analyzeSleep")

# Subtract 1 from number of elements in modality, because first index is 0.
nModalities=$((${#modality[@]}-1))

for subject in {0001..113}; 
do

	for i in $(seq 0 $nModalities);
	do 
		
		# Check if output features file exists, if not run analysis. 
		if ! [ -a "${baseFolder}/${modality[i]}/btmn_${subject}_${modality[i]}_features.csv" ]
		then
			# Submit job.
			qsub ./${modality[i]}/${scriptName[i]}.sh $subject
		fi	
		echo 
		
	done
	
done
