BEGIN {FS = ","; total=0;}  #BEGIN: Executes once before file processed. Sets input field separators to comma for csv processing. Initialises a total variable to store running total of duration of all journeys for route

function calculateJourneyDuration(){
    duration = $(NF-2)-$1; #Calculates journey duration in seconds by subtracting timestamp of first stop (indexed as 1st field in record) from timestamp last stop (indexed as 3rd field from the end of record) 
    return duration;
}

function calculateMeanRouteDuration(total){ #Calculate mean route time
    mean = total/FNR; #Calculates mean journey duration for route by dividing total duration of all journeys of route by number of journeys (number of records in file as processed by script i.e. excluding header)
    return mean;
}

{total += calculateJourneyDuration();} #Executes for each record processed. Calls function to update total time for route with journey duration for current record

END {  #END: Executes once after all records processed. Calls method and prints the mean journey duration for the route            
    print calculateMeanRouteDuration(total);
    } 
