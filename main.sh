#! /bin/sh

# Folder and date specification.
baseDir="/someren/projects/btmn/analysis/amb"
date="170308"

modality=("ambient-humidity" 
"ambient-light" 
"ambient-temperature" 
"baro-pressure"
"contact-temperature" 
"movisens-temperature" 
"activity" 
"posture" 
"sleep")

scriptName=("analyzeAmbientHumidity" 
"analyzeAmbientLight" 
"analyzeAmbientTemperature"
"analyzeBaroPressure" 
"analyzePhilipsContact" 
"analyzeMovisensTemperature" 
"analyzeActivity" 
"analyzePosture" 
"analyzeSleep")

# Add ecg...

# Override with single modalities if required.
#modality=("ambient-humidity")
#scriptName=("analyzeAmbientHumidity")

# Subtract 1 from number of elements in modality, because first index is 0.
nModalities=$((${#modality[@]}-1))

for i in $(seq 0 $nModalities);
do
    
    # Check if the output directory exists, if not create.
    if ! [ -d "${baseDir}/${modality[i]}/${date}" ]
    then
    
        # Create directory
        mkdir ${baseDir}/${modality[i]}/${date}
            
    fi
    
    # Check if the log directory exists, if not create.
    if ! [ -d "${baseDir}/${modality[i]}/logs" ]
    then
    
        # Create directory
        mkdir ${baseDir}/${modality[i]}/logs
        
    fi

    for subject in {0001..1}; 
    do

        # Check if output features file exists, if not run analysis. 
		if ! [ -a "${baseDir}/${modality[i]}/${date}/btmn_${subject}_${modality[i]}_features.csv" ]
		then
		    # Submit job.
			qsub ./${modality[i]}/${scriptName[i]}.sh $subject $date
		fi	 
    done
done
