clear; clc

%@author info, Feb2021
%This script goes into the IVFCR folder, goes into all folders that have LENA data, copy all .its in all folders into a new folder so pre-processing can be done

%Edited: March 2022: changes made to go to IVFCR Study Renamed folder and get the more complete corpus of .its files from there. Also makes two .csv files: one with filenames and infant ID; 
% and the other with renamed and old file names + infant ID. 

%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
%SOME NOTES:
    %-If you don't have all your .its files in a single folder, this is the first script you schould run. YOU WILL NOT NEED THIS IF YOUR DATA IS ALREADY ORGANISED INTO A FOLDER OF
      %.its FILES 
    %-As of April 2021, there is a NOT_IVFCR folder in LENA_Exports (not named as such in the renamed folder). I have coded in not including the .its files for this directory. If there are
      %other .its files you would like to not include, please delete them manually after copying, or adapt this script accordingly
  
%CHANGE ALL PATHS AND STRINGS ACCORDINGLY
BasePath = '~/BaseDataPath/';%This is the base path to the destination directory (this is an anonymised dummy link; change accordingly)
destinationpath = strcat(BasePath,'Data/LENAData/A1_ItsFiles/'); %Insert your destination path
cd ~/BaseCloudPath/LENAExports_Renamed/ %Insert your path where .its files are (this is an anonymised dummy link; change accordingly)
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------

NotIvfcrId = '941'; %specifiy which infant ID is NOT-IVFCR
ItsDirs = dir; %All folders with LENA data are in here. Use dir to get the list of these directories
dirFlags = [ItsDirs.isdir]; %Identify the elements of ItsDirs that are folders/directories (logical vector: 1 means the item is, indeed, a directory)
Ctr = 0; %Initialise counter variable

%Below, we get the path to each relevant directory
for i = 1:numel(ItsDirs) %Loop through directory list

    i

    if (dirFlags(i) == 1) && (contains(ItsDirs(i).name,NotIvfcrId)~=1) %if it is a directory, AND if it is not the NOT_IVFCR folder, which is folder 0941, go in, find path, etc. 

        s = what(ItsDirs(i).name); %'what' gets the path to the directory if its name is shown. (I am not sure how foolproof this is, like what happens when there are 2 distinct directories 
        % with the same name? This is not quite clear to me from the help page: https://www.mathworks.com/help/matlab/ref/what.html. But, it works, so this is how it shall be)
        cd(s.path); %Go into the relevant directory
        ItsList = dir('*.its'); %This is just to have a .txt file that has file names and corresponding Infant codes, just in case. This also helps to check if there are no .its files

        if ~isempty(ItsList) %Proceed if there ARE .its files
            for j = 1:numel(ItsList)
                Ctr = Ctr + 1; %Update Ctr
                FNRoot{Ctr,1} = strrep(ItsList(j).name,'.its',''); %remove .its from file name
                TempInfCode = strtrim(ItsDirs(i).name); %get infant ID from folder name

                %optional code to use file name to compute age
                        % AgeStringPre = strsplit(FNRoot{Ctr,1},'_'); %split filename at the underscore; Age is the second substing
                        % AgeString = AgeStringPre{2};
                        % AgeString = AgeString(isletter(AgeString) ~= 1); %remove any letters from string
                        % %the first two of this is the year, the second two
                        % %characters teh month, and the last two the age in days
                        % InfantAge(Ctr,1) = str2num(AgeString(1:2))*365 + str2num(AgeString(3:4))*30 + str2num(AgeString(5:6));
             
                if strcmp(TempInfCode(1),'0') == 1 %Remove extra 0 from the start of infant code string
                    TempInfCode(1) = [];
                end

                InfantID{Ctr,1} = TempInfCode; %Store infant ID
                fileID = fopen(ItsList(j).name); %Get file id for each file
    
                while ~feof(fileID) %while loop terminated at end of file, so this goes on till the end of file or otherwise breaks

                    myline = fgetl(fileID); %Goes through line by line
                    if contains(myline,'<ITS fileName="') 
                        myline = strrep(myline,'<ITS fileName="','');
                        mylineSplit = strsplit(myline,'"');
                        OldFNRoot{Ctr,1} = strcat('e',mylineSplit{1}); %Add 'e' to the front of old fiile name
                        break
                    end
                end
            end
            copyfile('*.its',destinationpath); %copy all .its files to teh destination
        end

      cd ~/BaseCloudPath/LENAExports_Renamed/ %Go back to IVFCR Coding folder so the loop can repeat  
    end
end

%Write table with files names and infant codes
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
cd(strcat(BasePath,'Data/MetadataFiles/')); %path for metadata files; CHANGE ACCORDINGLY
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
TablewOldFn = table(FNRoot,OldFNRoot,InfantID); writetable(TablewOldFn,'ItsFileDetailsWOldFN.csv')
TableToShare = table(FNRoot,InfantID); writetable(TableToShare,'ItsFileDetailsShareable.csv')

        