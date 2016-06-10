%This is meant to be the analysis code for pairing experiments. This code
%should analyze the tuning curves before and after, the playing of long
%tones before and after, and the actual changes that may occur with laser
%light itself. 

fileName = '160609TonePairingTester';

%% Hardcoded Variables:
rpvTime = 0.0013; %limit to be considered an RPV.
clusterWindow = [-0.01,0.03]; %this is hardcoded for consistency
trodesFS = 30000; %sampling rate of trodes box.
rasterWindow = [-1,3]; %duration of raster window. These are numbers that will
%be multiplied by the tone duration. EX: raster window for 0.1sec tone will
%be -100 to 300 ms.
histBin = 0.005; %bin size in seconds
clims1 = [-1 1]; %limits for the range of heatmaps for firing. Adjust if reach saturation. Currently based on log10


%% Establishes the folder and subfolders for analysis. Adds all folders to
%path for easy access to files.
homeFolder = pwd;
subFolders = genpath(homeFolder);
addpath(subFolders)
subFoldersCell = strsplit(subFolders,';')';

%% generate a master structure for storage of everything.
masterStruct = struct;

%% Find and ID Matclust Files for Subsequent Analysis.
[matclustFiles] = functionFileFinder(subFoldersCell,'matclust','matclust');

%extracts matclust file names and removes periods which allow structured
%array formation.
truncatedNames = matclustFiles;
numTrodes = length(truncatedNames);
for i = 1:length(truncatedNames)
    truncatedNames{i} = truncatedNames{i}(1:find(truncatedNames{i} == '.')-1);
    masterStruct.(truncatedNames{i}) = [];
end

%generates even shorter names for figure presentation. 
trodesDesignation = cell(size(truncatedNames));
for i = 1:length(truncatedNames)
    trodesDesignation{i} = truncatedNames{i}(17:end);
end

%% Goes and pulls spike times, overall firing rate, waveforms, rpvs from matclust files
[masterStruct] = functionPairingSpikeExtractor(truncatedNames,...
    matclustFiles,rpvTime,clusterWindow,masterStruct);

%% First thing is to import the sound file data.

soundName = strcat(fileName,'.mat');
soundFile = open(soundName);
soundFile = soundFile.fullData;


%% This code extracts DIO timepoints and states, and uses that information to
%%extrapolate which timepoints represent upward changes in the DIO. These
%%represent true TTL pulses.

%extract DIO filenames
[D1FileName] = functionFileFinder(subFoldersCell,'DIO','D1');
D1FileName = D1FileName{1};
[D2FileName] = functionFileFinder(subFoldersCell,'DIO','D2');
D2FileName = D2FileName{1};

%extract actual data
[DIO1Data] = readTrodesExtractedDataFile(D1FileName);
[DIO2Data] = readTrodesExtractedDataFile(D2FileName);

%remove just time and state data. convert to double for easier processing
DIO1Data = double([DIO1Data.fields(1).data,DIO1Data.fields(2).data]);
DIO2Data = double([DIO2Data.fields(1).data,DIO2Data.fields(2).data]);

%pull all differences in state for DIO data (diff subtracts x(2)-x(1)). +1
%fudge factor adjusts for indexing. MUST BE DOUBLE!!
DIO1Diff = find(diff(DIO1Data(:,2))==1)+1;
DIO1High = find(DIO1Data(:,2) == 1);
%finds all points which are down to up states, extracts these times.
DIO1True = intersect(DIO1Diff,DIO1High);
DIO1True = DIO1Data(DIO1True,1);
%finds differences between time points
DIO1TrueDiff = diff(DIO1True);

%% pull variables from soundfile regarding signal TTLs to calculate acceptable range of signals for signal TTLs
signalPulseNum = soundFile.DividerTTLNumber;
signalITI = soundFile.DividerTTLiti; %signal TTL ITI in seconds
acceptRange = [0.9,1.1]; %range of values above or below ideal ITI that are acceptable
signalITI = signalITI*30000; %converts to trodes timestamps
signalRange = acceptRange*signalITI;

%% This next part finds all TTLs that are markers. This finds the ones that
%correspond with diff. This will correctly label the first three pulses of
%every sequence
findSignals = find(DIO1TrueDiff>signalRange(1) & DIO1TrueDiff<signalRange(2));
%generates array to hold first and last signal pulses, fills based on
%information about number of signal pulses
signalHolder = zeros(2,size(findSignals,1)/(signalPulseNum-1));
for i = 1:size(findSignals,1)/(signalPulseNum-1)
    signalHolder(1,i) = findSignals(1+(signalPulseNum-1)*(i-1));
    signalHolder(2,i) = signalHolder(1,i) + signalPulseNum - 1;
end

%% This now uses hardcoded values to extract the TTLs and time periods for each stage
%of the experiment. Currently, times are in Trodes samples, which are at 30
%kHz.
timesBaseline = [DIO1Data(1,1),DIO1True(signalHolder(1,1))];
timesTuningFirst = [DIO1True(signalHolder(2,1)),DIO1True(signalHolder(1,2))];
timesPresentationFirst = [DIO1True(signalHolder(2,2)),DIO1True(signalHolder(1,3))];
timesPairing = [DIO1True(signalHolder(2,3)),DIO1True(signalHolder(1,4))];
timesPresentationSecond = [DIO1True(signalHolder(2,4)),DIO1True(signalHolder(1,5))];
timesTuningSecond = [DIO1True(signalHolder(2,5)),DIO1Data(end,1)];
%also using the same outputs from signalHolder, this determines which TTL
%pulses belong to which output. 
TTLsTuningFirst = DIO1True(signalHolder(2,1)+1:signalHolder(1,2)-1);
TTLsPresentationFirst = DIO1True(signalHolder(2,2)+1:signalHolder(1,3)-1);
TTLsPairing = DIO1True(signalHolder(2,3)+1:signalHolder(1,4)-1);
TTLsPresentationSecond = DIO1True(signalHolder(2,4)+1:signalHolder(1,5)-1);
TTLsTuningSecond = DIO1True(signalHolder(2,5)+1:end);
%stores these values into the master structure. Converts to seconds.
masterStruct.TTLs.TuningFirst = TTLsTuningFirst/trodesFS;
masterStruct.TTLs.TuningSecond = TTLsTuningSecond/trodesFS;
masterStruct.TTLs.PresentationFirst = TTLsPresentationFirst/trodesFS;
masterStruct.TTLs.PresentationSecond = TTLsPresentationSecond/trodesFS;
masterStruct.TTLs.Pairing = TTLsPairing/trodesFS;
%Remember that this has converted time values to seconds.
masterStruct.TimePeriods.Baseline = timesBaseline/trodesFS;
masterStruct.TimePeriods.TuningFirst = timesTuningFirst/trodesFS;
masterStruct.TimePeriods.TuningSecond = timesTuningSecond/trodesFS;
masterStruct.TimePeriods.PresentationFirst = timesPresentationFirst/trodesFS;
masterStruct.TimePeriods.PresentationSecond = timesPresentationSecond/trodesFS;
masterStruct.TimePeriods.Pairing = timesPairing/trodesFS;

%% check size!if the wrong size will throw error!
if size(TTLsPresentationFirst,1) == soundFile.PresentationRepetitions;
    disp('Correct Number of Early Long Presentations')
else
    error('MISMATCHED EARLY LONG PRESENTATIONS') 
end

if size(TTLsPresentationSecond,1) == soundFile.PresentationRepetitions;
    disp('Correct Number of Second Long Presentations')
else
    error('MISMATCHED SECOND LONG PRESENTATIONS') 
end

if size(TTLsTuningFirst,1) == soundFile.TuningRepetitions;
    disp('Correct Number of Early Tuning Presentations')
else
    error('MISMATCHED EARLY TUNING PRESENTATIONS') 
end

if size(TTLsTuningSecond,1) == soundFile.TuningRepetitions*soundFile.SecondTuningRatio;
    disp('Correct Number of Late Tuning Presentations')
else
    error('MISMATCHED LATE TUNING PRESENTATIONS') 
end


%% First thing I want to do is divvy up spikes to different time periods
[masterStruct] = functionPairingSpikeSeparator(masterStruct,...
   truncatedNames);

%% calculates average firing rate for the initial period.
[masterStruct] = functionPairingAverageRate(masterStruct,truncatedNames);

%% Next thing is to analyze tuning curve chunks for differences.

%Analyze first tuning curve. These hardcoded names will pull the right TTL
%and spike files.
spikeName = 'TuningFirstSpikes';
ttlName = 'TuningFirst';
soundName = 'Tuning1';

%first pull out sound data for the relevant file
[masterStruct] = functionPairingSoundDataExtraction(masterStruct,...
    soundName,soundFile); 
%next, pull tuning information
[masterStruct] = functionPairingTuning(masterStruct,truncatedNames,...
    spikeName,ttlName,soundName,rasterWindow,histBin,clusterWindow,...
    clims1,rpvTime,trodesDesignation,fileName); 

%now I analyze the second tuning curve. again, hardcoded names pull the
%correct TTL and spike files.
spikeName = 'TuningSecondSpikes';
ttlName = 'TuningSecond';
soundName = 'Tuning2';

%first pull out sound data for the relevant file
[masterStruct] = functionPairingSoundDataExtraction(masterStruct,...
    soundName,soundFile); 
%next, pull tuning information
[masterStruct] = functionPairingTuning(masterStruct,truncatedNames,...
    spikeName,ttlName,soundName,rasterWindow,histBin,clusterWindow,...
    clims1,rpvTime,trodesDesignation,fileName); 

%% Next I analyze the first and second long tone presentations



















