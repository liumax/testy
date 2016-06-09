%This code is meant to use time periods delineated by signal pulses to
%separate out chunks of spike times. This will save these spike files in
%the spikeStruct file.

function [spikeStruct] = functionPairingSpikeSeparator(masterStruct,...
    spikeStruct,truncatedNames);
%First, I want to pull all the time periods.
timesBaseline = masterStruct.TimePeriods.Baseline;
timesTuningFirst = masterStruct.TimePeriods.TuningFirst;
timesPresentationFirst = masterStruct.TimePeriods.PresentationFirst;
timesPairing = masterStruct.TimePeriods.Pairing;
timesPresentationSecond = masterStruct.TimePeriods.PresentationSecond;
timesTuningSecond = masterStruct.TimePeriods.TuningSecond;

%stores spikes as separated spike times. 
for i = 1:size(truncatedNames,2);
    for j = 1:spikeStruct.(truncatedNames{i}).Clusters
        spikeStruct.(truncatedNames{i}).BaselineSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesBaseline(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesBaseline(2));
        spikeStruct.(truncatedNames{i}).TuningFirstSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesTuningFirst(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesTuningFirst(2));;
        spikeStruct.(truncatedNames{i}).TuningSecondSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesTuningSecond(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesTuningSecond(2));;
        spikeStruct.(truncatedNames{i}).PresentFirstSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesPresentationFirst(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesPresentationFirst(2));;
        spikeStruct.(truncatedNames{i}).PresentSecondSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesPresentationSecond(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesPresentationSecond(2));;
        spikeStruct.(truncatedNames{i}).PairingSpikes = ...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}(...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}>timesPairing(1) &...
            spikeStruct.(truncatedNames{i}).SpikeTimes{j}<timesPairing(2));;
    end
end


end
