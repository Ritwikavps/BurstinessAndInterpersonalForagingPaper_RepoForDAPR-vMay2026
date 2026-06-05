`A1_ReliabilityMaster.m` is the only executable script in this folder with all other scripts being required user-defined functions. This script generates comprehensive reliability metrics (Cohen's kappa, percent agreement, false alarm rate, miss rate, confusion rate, identification error rate, precision, recall) at the validation data file level as well as the 5-minute section level for LENA 5-minute data tested against human listener labelled 5-minute sections with all adult vocalisations included and with only infant-directed adult vocalisations included. For methodological details, see relevant scripts as well as supplementary section S5 in the Burstiness paper.

Reliability metrics are computed after 5-minute sections are chopped up into 1 ms frames (`Get1msVocChunks.m`; error checks in this process are done using `CheckErrorsIn1msVocChunkFile.m` for randomly chosen validation files). 

The functions `GetPrecisionAndRecallMats.m` and `GetReliabilityErrorNum.m` are used to estimate reliability metrics. 

The computed reliability numbers (using MATLAB's `confusionmat` function) are tested against reliability numbers estimated by explicitly writing code using `CheckReliabilityNumFrames_MatlabVsUser.m`. Finally, several common sense checks are carried out using `MasterChecksForReliability_HumVsLENA.m`.

For more specific details, please read comments about paths and other notes in the files before executing them.
