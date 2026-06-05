function [DurationTab] = GetUttDurations(FileList,MetadataTab,FileStr)

%This function reads in time series files and gets utterance durations and corresponding ages from time series data. This function does this for LENA day-long, 
% LENA 5 min, and human-listener labelled data.
%Inputs: - FileList: list of files
%        - MetadataTab: table with metadata info to get age info
%        - FileStr: string to remove from file name to get file name root.

DurForTab = []; %initialise empty vector to store duration in 
SpkrForTab = {}; %vector for speaker labels
AgeForTab = []; %vector for age
FnameUnmergedForTab = {}; %vector for file name (unmerged, at subrecording level)

for i = 1:numel(FileList) %go through list of files

    DataTab = readtable(FileList(i).name); %read table
    %Kids, this is why you retain consistency in variable naming across data. As such, this is intended to adjust to the situation where LENA data has 
    % 'FileNameUnMerged' while validation data has 'FnameUnmerged'. 
    if ~isempty(DataTab.Properties.VariableNames(contains(DataTab.Properties.VariableNames,'FnameUnmerged')))
        DataTab = renamevars(DataTab,'FnameUnmerged','FileNameUnMerged'); 
    end
    Fname = erase(FileList(i).name,FileStr); %get file name root
    FnRoot = Fname(1:11); %get just the root (without the subrec info)
    
    if size(DataTab,1) ~= 0  %mandatory checks ; if table is empty, then this whole exercise is pointless.    
  
        DurForTab = [DurForTab; DataTab.xEnd - DataTab.start]; %append duration to vector

        %similarly for other vectors
        SpkrForTab = [SpkrForTab; DataTab.speaker];
        AgeFromMetadata = MetadataTab.InfantAgeMonth(contains(MetadataTab.FileNameRoot,FnRoot)); %get infant age corresponding to teh file
        AgeForTab = [AgeForTab; AgeFromMetadata*ones(size(DataTab.start))]; %add to age vector
        FnameUnmergedForTab = [FnameUnmergedForTab; DataTab.FileNameUnMerged];
    end
end

DurationTab = table(DurForTab,SpkrForTab,AgeForTab,FnameUnmergedForTab); %set up output table
DurationTab.Properties.VariableNames = {'Duration','Speaker','InfAgeMnth','FnameUnmerged'}; %set varnames

