batman
======

This repository contains the code and instructions necessary to reproduce
the data analyses of the [STW][stw]-funded project [BATMAN][batman].

[batman]: http://www.neurosipe.nl/project.php?id=23&sess=6eccc41939665cfccccd8c94d8e0216f
[stw]: http://www.stw.nl/en/

## Ambulatory data

The BATMAN (Behavior, Alertness, and Thermoregulation: a Multivariate ANalysis)
project pursues to identify major thermoregulatory system parameters, and their
effects on behaviour and alertness, in a completely unrestrained ambulatory
setting. Achieving this goal will involve ambulatory measurement of all relevant
inputs and outputs: physical activity, posture, environmental light, temperature and 
humidity, electrocardiography, and skin temperature by means of a
multi-sensor system as well as questionnaires and reaction times assessed on a
PDA. 

This repository deals with the extraction of valuable features (for modeling
purposes) from the ambulatory recordings obtained within the BATMAN project.

![Ambulatory protocol](/img/ambulatory-protocol.png "Ambulatory protocol")

## What have we done with the BATMAN dataset?

The table below lists all the analyses and processing tasks that have been or will be 
performed on the BATMAN dataset, roughly in chronological order.

What?                                                 | Documentation
----------------------------------------------------- | -------------
Data splitting                                        | [+btmn/+splitting/README.md][split]
Pre-processing                                        | [+btmn/+preproc/README.md][preproc]
Extraction of skin temperature                        | [+btmn/+skintemp/README.md][skintemp]
Extraction of activity + posture                      | [+btmn/+activity/README.md][act]
Extraction of heart rate variability (HRV) features   | [+btmn/+hrv/README.md][hrv]
Extraction of ambient-light                           | [+btmn/+light/README.md][light] 
Extraction of ambient temperature + humidity          | [+btmn/+environment/README.md][environ]
Extraction of sleep features                          | [+btmn/+sleep/README.md][sleep]
Extraction of mobile data                             | [+btmn/+mobile/README.md][mobile]
Statistical analysis of ambulatory data               | [+btmn/+stats/README.md][stats]

[split]:    ./+btmn/+splitting/README.md
[preproc]:  ./+btmn/+preproc/README.md
[skintemp]: ./+btmn/+skintemp/README.md
[act]:      ./+btmn/+activity/README.md
[hrv]:      ./+btmn/+hrv.README.md
[light]:    ./+btmn/+light/README.md
[environ]:  ./+btmn/+environment/README.md
[sleep]:    ./+btmn/+sleep/README.md
[mobile]:   ./+btmn/mobile/README.md
[stats]:    ./+btmn/+stats/README.md


## Sensor data

Data was collected from a multi-sensor system. The following variables were recorded:

Sensor           | Body location | Variable         | Sampling frequency  | Data format
-----------------|---------------|------------------|---------------------|----------------
Movisens MoveII  | Thigh, wrist  | 3D accelerometry | 64 Hz               | binary
                 |               | baro pressure    | 2 Hz                | binary
                 |               | skin temperature | 2 Hz                | binary
Movisens EkgMove | Chest         | ECG              | 1024 Hz             | binary
                 |               | 3D accelerometry | 64 Hz               | binary
                 |               | baropressure     | 2 Hz                | binary
                 |               | skin temperature | 2 Hz                | binary
Dimesimeter      | Inner & outer clothing, chest | Light | |
iButton          | Inner & outer clothing, chest | Temperature | |
                 |               | Humidity         |
Philips          | Index finger  | skin temperature | 2 Hz                | csv
Mobile phone     |               | subjective       | 10/day              | csv


## Importing data

All the data obtained in the BATMAN project was converted to time series objects. Due to 
the various data formats of the devices there are import/load scripts for every sensor. 

## Data splitting

The multi-sensor system recorded physiological and environmental variables throughout the week. For 
modeling purposes only the data around the alarms of the mobile phone were of interest, as 
these were the moments that subjective and objective vigilance measures were obtained.

Objective measures of vigilance were obtained by a 3-minute version of the Psychomotor 
Vigilance Task implemented on a Nexus 4 running an aftermarket version of Android: CyanogenMod.
Subjective measures of fatigue and vigilance were obtained by a questionnaire.

Using the time stamps of the phone alarms, the data was split into data sections starting
15min prior to the alarm and stopped 20 minutes later (i.e. 5 minutes after the alarm).   

