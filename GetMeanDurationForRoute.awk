BEGIN {FS = ","; total=0;} #set field separator to comma

function calculateJourneyDuration(){
    duration = $(NF-2)-$1;           
    return duration;
}

function calculateMeanRouteDuration(total){ #Calculate mean route time
    mean = total/FNR;
    return mean;
}

{total += calculateJourneyDuration();} #Update total time for route with journey duration at each line

END {            
    #print "done";
    print calculateMeanRouteDuration(total);
    } #Function call to calculate mean
