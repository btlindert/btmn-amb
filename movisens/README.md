movisens
======

Data extracted from Movisens sensors comes in a subject specific folder (e.g. /0001) 
with specific filenames for each modality: ecg.bin, skintemp.bin, press.bin, acc.bin.

However, data storage in our lab requires storing data under specific filenames that 
include the study, modality, subjectId etc. E.g. btmn_0001_ecg.bin.

Unfortunately, the Movisens Matlab Toolbox checks for specific filenames (e.g. ecg.bin) when 
importing to Matlab. Rather than rewriting the Movisens Toolbox, I solved this by generate 
symbolic links on the fly from Matlab to create a link named 'ecg.bin' to specific files 
like 'btmn_0001_ecg.bin.   

