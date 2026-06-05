#%@author info, June 2022
#This script contains functions used to parse .eaf files
#Required libraries: sjmisc, stringr, pracma
#also make sure to be in the correct directory

########################################################################################################################################################################
#Function 1: Gets Time ref and corresponding time values from the block before annotations start
########################################################################################################################################################################
GetEafTimeRefTimeValue <- function(EafFileName){ 

  #Time slot lines are of the form: <TIME_SLOT TIME_SLOT_ID="ts1" TIME_VALUE="5160136"/>
  #first, establish a connection (which is an interface to the file) to the desires .eaf file
  myCon = file(description = EafFilename, open="r", blocking = TRUE) #establish connection
  
  #initialise counter variable as well as vectors to store info in
  TimeSlotRef <- c()
  TimeVal <- c()
  TSref_ctr = 0
  
  repeat{ #repeat till line is the empty vector
    myLine = str_trim(readLines(myCon, n = 1)) # Read one line from the connection.
    
    #time slot ref and time matching block
    if(str_contains(myLine,'<TIME_SLOT TIME_SLOT_ID="')){
      
      #get time slot ref
      TSref_ctr = TSref_ctr + 1
      
      #first, sub <TIME_SLOT TIME_SLOT_ID=" with empty, then sub everything from and after" TIME_VALUE="
      #with empty, and finally
      TimeSlotRef[TSref_ctr] = gsub('" TIME_VALUE=".*','',gsub('<TIME_SLOT TIME_SLOT_ID="','',myLine))
      
      #get corresponding time
      #remove everything up to .*" TIME_VALUE=", then remove "/>' and convert to numeric
      TimeVal[TSref_ctr] = as.numeric(gsub('"/>','',gsub('.*" TIME_VALUE="','',myLine)))
    }
    if(identical(myLine, character(0))){
      break
    } # If the line is empty, exit.
    #print(myLine) # Otherwise, print and repeat next iteration.
  }
  
  #Explicitly opened connection needs to be explicitly closed.
  close(myCon)
  rm(myCon)
  
  #create output dataframe
  TimeRefVal_df <- data.frame(TimeSlotRef,TimeVal)
  return(TimeRefVal_df)
}

########################################################################################################################################################################
#Function 2: Gets all the details of annotations; outputs timeref 1 and 2, annotation, and annotation id, as well as line numbers for each
########################################################################################################################################################################
GetAnnotationDetails <- function(EafFileName){ 
  
  #define empty output df. This ca  be redefined if there *is* valid output
  TierInfo_df <- data.frame(matrix(ncol = 0, nrow = 0))
  
  #list of key tiers
  KeyTierList = c('Infant Voc Type', 'Adult Utterance Dir', 'Adult Ortho')
  
  ####################################################################################
  #we do this in three blocks: first, we identify all the tiers in the file, then we identify the line numbers associated with the
  #start and end of each annotation tier, and then, we parse out annotation details in each tier
  #first, establish a connection (which is an interface to the file) to the desires .eaf file
  #This is a little bit of an overkill, but this way, we get to be very thorough and make sure we are not making errors
  myCon_TierIdList = file(description = EafFilename, open="r", blocking = TRUE) #establish connection
  
  #id all tier IDs; initialise lists to store tier info in 
  TierIdIndexNum = 0 #initialise index variable for vector to store tier IDs
  TierIdVec = c() #initialise vector to store tier IDs
  
  #initialise counter variables, line number variable, as well as vectors to store annotation info in; basically everything to store annotation details in
  LineNum = 0
  StartTimeRef <- c()
  StartTimeLineNum <- c()
  StartTime_ctr = 0
  EndTimeRef <- c()
  EndTimeLineNum <- c()
  EndTime_ctr = 0
  AnnotId <- c()
  AnnotIdLineNum <- c()
  AnnotId_ctr = 0
  Annotation <- c()
  AnnotationLineNum <- c()
  Annotation_ctr = 0
  TierTypeVec <- c() #vector with the tier type string repeated
  
  repeat{ #repeat till line is the empty vector
    
    myLine = str_trim(readLines(myCon_TierIdList, n = 1)) # Read one line from the connection.
    LineNum = LineNum + 1 #increment line num
    
    if (identical(myLine, character(0))){ #first check if line is empty
      break
    } # If the line is empty, exit. Assign last line in the file as the tier end line num
    
    #Then check to identify the start of valid tiers (Excluding the first 'default' tier)
    #While the standrad tier identifier text is '<TIER LINGUISTIC_TYPE_REF="', tiers created in the music labelling pass (not relevant for the 
    #burstiness paper) and later passes have identifiers '<TIER DEFAULT_LOCALE="en" LINGUISTIC_TYPE_REF="'. Therefore, I use the common text in 
    #both these to identify tiers. This means that there are sometimes duplicates in the parsed data. However, these duplicates are not in the infant
    #voc type or adult utterance tiers, which are the relevant tiers for the burstiness paper, so no downstream action has been taken for this isse.
    if ((str_contains(myLine,'LINGUISTIC_TYPE_REF="')) && (str_contains(myLine,'TIER_ID="'))){
      #Tier id lines are normally of the form: <TIER LINGUISTIC_TYPE_REF="default-lt" TIER_ID="Infant Voc Type">
      #(see comments above for more details)
      
      #get tier id for the tier
      TierIdCurrent = gsub('">','',gsub('.*TIER_ID="','',myLine))
      
      #check that the the tier id is not the default id
      if  (!(str_contains(TierIdCurrent,'default',ignore.case = TRUE))){ #we don't want to include 
        #the defauilt tier, so only proceed if current tier id does not conatin 'default'
        
        #update vector and counter variable
        TierIdIndexNum = TierIdIndexNum + 1
        TierIdVec[TierIdIndexNum] = TierIdCurrent
      }
    }  
    
    if (TierIdIndexNum > 0){ #if the tier id index number is non-zero, then we kow we are in the tiers
      #Now, we proceed to get the annotation info
      #we will check for each type of info (time slot refs, annotation id, annotation) independelty
      #annotation ID
      #Note that if a specific condition is not satisfied in detecting each of these items,
      #the vector to store the item will be populated by NA by default
      #This is another reason why we want to check for each item separately
      if (str_contains(myLine,'ALIGNABLE_ANNOTATION ANNOTATION_ID="')){ 
        
        #relevant blocks in the .eaf files look like this:
        #<ALIGNABLE_ANNOTATION ANNOTATION_ID="a413"
        #TIME_SLOT_REF1="ts51" TIME_SLOT_REF2="ts52">
        #In the very first clean up pass, the annotation line looked like this: 
        #<ALIGNABLE_ANNOTATION ANNOTATION_ID="a39" TIME_SLOT_REF1="ts723" TIME_SLOT_REF2="ts724">
        #The code below reflects this format, and since attempting to remove '" TIME_SLOT_REF1=".*' only results in the annotation 
        #id having an extra trailing ", I am going to leave it be.
        
        AnnotId_ctr = AnnotId_ctr  + 1
        AnnotId[AnnotId_ctr] = gsub('" TIME_SLOT_REF1=".*','',
                                    gsub('<ALIGNABLE_ANNOTATION ANNOTATION_ID="','',myLine))
        AnnotIdLineNum[AnnotId_ctr] = LineNum
      }
      
      #time slot ref1
      if (str_contains(myLine,'TIME_SLOT_REF1="')){
        
        StartTime_ctr = StartTime_ctr + 1
        StartTimeRef[StartTime_ctr] = gsub('" TIME_SLOT_REF2=.*','',
                                           gsub('.*TIME_SLOT_REF1="','',myLine))
        StartTimeLineNum[StartTime_ctr] = LineNum
      }
      
      #time slot ref1
      if (str_contains(myLine,'TIME_SLOT_REF2="')){
        
        EndTime_ctr = EndTime_ctr + 1
        EndTimeRef[EndTime_ctr] = gsub('">','',
                                       gsub('.*TIME_SLOT_REF2="','',myLine))
        EndTimeLineNum[EndTime_ctr] = LineNum
      }
      
      #Annotation
      if (str_contains(myLine,'<ANNOTATION_VALUE')){ #we ue this stribg because some files have <ANNOTATION_VALUE/>
        #instead of <ANNOTATION_VALUE>X</ANNOTATION_VALUE> where X is a sample annotation
        
        #The annotation line looks like this: <ANNOTATION_VALUE>uh</ANNOTATION_VALUE>
        
        Annotation_ctr = Annotation_ctr + 1
        Annotation[Annotation_ctr] = gsub('>','',gsub('</ANNOTATION_VALUE>','',
                                                      gsub('<ANNOTATION_VALUE','',myLine)))
        AnnotationLineNum[Annotation_ctr] = LineNum
        TierTypeVec[Annotation_ctr] = TierIdCurrent
      }
    }
  }
  
  #Explicitly opened connection needs to be explicitly closed.
  close(myCon_TierIdList)
  rm(myCon_TierIdList)
  
  #check whether the numel of starttimeref, endtimeref, annotId and annotation are the same
  CtrNumCheck = abs(StartTime_ctr-EndTime_ctr) + abs(EndTime_ctr-AnnotId_ctr) + abs(AnnotId_ctr-Annotation_ctr)
  if (CtrNumCheck == 0){ #if these counter numbers are the same, implying that the number of instances
    #of start times, end times, annotation ids and annotations are the same, create output dfr if else
    
    TierInfo_df <- data.frame(StartTimeRef,StartTimeLineNum,EndTimeRef,EndTimeLineNum,AnnotId,AnnotIdLineNum,Annotation,AnnotationLineNum,TierTypeVec)
  } else { #if not, create empty df + output error message
    print(sprintf('Mismatch in number of start time ref, end time ref, annotation id, and/or annotation in eaf file %s',EafFilename))
  }
  
  #check if file has key tiers
  for (j in 1:numel(KeyTierList)){
    if (sum(grepl(KeyTierList[j],TierIdVec)) == 0){#if there isn't a block for desired tier, print error message
      #(Note that there are sometimes multiple instances of the same tier with only one of them having annotations (based on examples I have looked at))
      print(sprintf('No %s tier in file %s',KeyTierList[j],EafFilename))
    }
  }
  return(TierInfo_df)
}

########################################################################################################################################################################
#Function 3: Matches Time ref to time value in the annotation detail df
########################################################################################################################################################################
MatchAnnotTimeRefToTime <- function(StartTimeRef,EndTimeRef,TimeRefVec,TimeValVec){ 
  
  #initialise vectors to store values
  StartTimeVal <- vector(mode="double",length=numel(StartTimeRef))
  EndTimeVal <- vector(mode="double",length=numel(EndTimeRef))
  
  #go through start time ref and time value vectors and match
  for (i in 1:numel(StartTimeRef)){
    for (j in 1:numel(TimeRefVec)){
      
      #check if strings match and get corresponding start time value; we can do this for start and end time refs in the same for loop block
      #because both have the same number of elements. But, to be extra paranoid, I am doing this in two blocks
      if (strcmp(StartTimeRef[i],TimeRefVec[j])==1){
        StartTimeVal[i] = TimeValVec[j]
      }
    }
  }
  
  #go through end time ref and time value vectors and match
  for (i in 1:numel(EndTimeRef)){
    for (j in 1:numel(TimeRefVec)){
      if (strcmp(EndTimeRef[i],TimeRefVec[j])==1){
        EndTimeVal[i] = TimeValVec[j]
      }
    }
  }
  
  TimeMatched_df <- data.frame(StartTimeVal,EndTimeVal)
  return(TimeMatched_df) 
}

########################################################################################################################################################################
#Function 4: Master function to put all the above functions together and parse eaf files from a given directory, save a sink file with missing tier and other error 
#flags, and write output .csv file
########################################################################################################################################################################
GetParsedCsvFilesFromEaf <- function(EafFilename,DestinationPath,StrToRemoveToGetEafFnRoot,StrToAddForCsvFn){

  #get annotation time ref ids and times
  TimeRefTimeVal_df = GetEafTimeRefTimeValue(EafFilename)
  TierInfo_df = GetAnnotationDetails(EafFileName) 
  #print(i) #debug bit
  
  if (!isempty(TierInfo_df)){
    #match time ref id to actual times
    TimeMatched_df <- MatchAnnotTimeRefToTime(TierInfo_df$StartTimeRef,TierInfo_df$EndTimeRef,
                                              TimeRefTimeVal_df$TimeSlotRef,TimeRefTimeVal_df$TimeVal)
    
    #merge both dataframes
    EafDetails_df <- cbind(TierInfo_df,TimeMatched_df)
    
    #write to csv
    FnEafRemoved = strsplit(EafFilename,StrToRemoveToGetEafFnRoot) 
    #I have to do the following in two steps because for some reason, R cannot seem to handle if I do this as strcat(a,b,c)
    #It works if I do strcat(c('a','b','c')), which makes me a little mad
    FnCsv = strcat(strcat(DestinationPath,FnEafRemoved[[1]][1]),StrToAddForCsvFn)
    write.csv(EafDetails_df,FnCsv,row.names = FALSE)
    #note that the indexing of FnEafRemoved is [[1]][1] because it is a list. The [[1]] indexes the first row, and [1] is the first element of that row=
  }
}