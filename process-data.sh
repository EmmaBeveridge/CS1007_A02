#!/usr/bin/env bash

#GetFilesToProcess
#Function: Returns file names for files in /data subdirectory to be processed by script
#Arguments:
#$1: File path of processing directory with subfolders /data and /out 

GetFilesToProcess(){
    
    local use_test_files=false
    #Parse flags supplied to script
    while getopts 't' flag; do 
        case "$flag" in
        t) #Only -t is a valid flag: indicates test dataset to be used  
            use_test_files=true
            ;;
        ?)
            printf "%s\t$(date)\tERROR: Invalid flag supplied\n" "$0" >&2 #Write to stderr as cannot yet check processing directory with log file exists
            exit 1
            ;;
        esac
    done 
    shift "$(($OPTIND -1))" #OPTIND contains index of next argument to be processed by getopts command
                            #When end of options reached (getops returns with exit code != 0), OPTIND set to index of first non-option arg
                            #Use shift command to remove the first strings from positional params list - remove all options processed by getops so now non-option argument can be referred to by $1 variable
                            #Requires script to be called with options before arguments on command line as is bash convention
    
    PATH_TO_PROCESSING_DIRECTORY="$1"   
    #Check if directory exists
    if [ ! -d "$1" ];then
        printf "%s\t$(date)\tERROR: %s does not exist." "$0" "$1" >&2 #Write to stderr as no log file exists
        exit 1   
    fi

    {
    if [[ "$use_test_files" = true ]]; then
        printf "%s\t$(date)\tMESSAGE: Using testing data set\n" "$0"    
        FILES_TO_PROCESS=$(./filter.sh "$PATH_TO_PROCESSING_DIRECTORY") #Run filter.sh script to select 5 largest files as testing set
    else
        FILES_TO_PROCESS=$(ls "$PATH_TO_PROCESSING_DIRECTORY"/data) #Get names of all files in data directory to process
    fi
    } 1>>"$1/log.txt" 2>&1 #redirect stdout and stderr for block to log.txt    
}


#ProcessData
#Function: Use awk scripts to process files in FILES_TO_PROCESS to produce output written to files in /out
#Arguments:
ProcessData(){


    local path_to_data="$PATH_TO_PROCESSING_DIRECTORY/data"
    local path_to_out="$PATH_TO_PROCESSING_DIRECTORY/out"

    
    #Create new duration.csv file with header line to store mean duration for routes
    printf "route,duration\n" >"$path_to_out/duration.csv"
    
   
    #Create new engine.csv file with header line to store total fuel usage for vehicle by ID
    printf "id,fuel\n" >"$path_to_out/engine.csv"
    
    #Create temporary file to store fuel usage for vehicle by ID for each route
    printf ""> "$path_to_out/engineTemp.csv"

    while IFS= read -r route_file_name; do #Set IFS to empty string to remove any leading/trailing whitespace from lines. Read file names to process as lines from FILES_TO_PROCESS variable       
        route_name=${route_file_name%.*} #Remove .csv extension from filename to get route name
        mean_duration="$(tail -n +2 < "$path_to_data/$route_file_name"| awk -f "./GetMeanDurationForRoute.awk")" #route file data redirected into tail command to remove header row. Output from tail command piped to awk command as input to awk script to calculate mean duration of route. Command substitution quoted to allow exit code of awk cmd as last cmd in pipeline to be checked.
        if [ $? -ne 0 ]; then #awk cmd is last cmd in pipeline so can be accessed using $? variable. Non-zero exit code indicates error in processing file.
            printf "%s\t$(date)\tERROR: GetMeanDurationForRoute.awk cannot process file %s\n" "$0" "$route_file_name">&2 #Write error message to stderr which will be redirected to log        
        else #Further processing/ writing data of problematic file is prevented
            mean_duration_formatted=$(date -u -d @${mean_duration} +"%T") #awk script returns mean duration as seconds, use date command to convert to HH:MM:SS format
            printf "$route_name,$mean_duration_formatted\n" >> "$path_to_out/duration.csv" #Append route name and formatted mean duration of route to duration.csv file with fields delimited by comma
            route_fuel_sums="$(tail -n +2 < "$path_to_data/$route_file_name"| awk -f "./GetFuelSumsByIDForRoute.awk")" #route file data redirected into tail command to remove header row. Output from tail command piped to awk command as input to awk script to sum total fuel used by ID for vehicles for this route. Vehicle IDs and fuel total sums stored in variable. Command substitution quoted to allow exit code of awk cmd as last cmd in pipeline to be checked.
            if [ $? -ne 0 ]; then  #awk cmd is last cmd in pipeline so can be accessed using $? variable. Non-zero exit code indicates error in processing file.
                printf "%s\t$(date)\tERROR: GetFuelSumsByIDForRoute.awk cannot process file %s\n" "$0" "$route_file_name">&2 #Write error message to stderr which will be redirected to log      
            else #Writing data of problematic file is prevented
                printf "%s\n" "$route_fuel_sums" >> "$path_to_out/engineTemp.csv" #Vehicle IDs and fuel sums written to temporary engine processing file.
            fi
        fi
    done <<< "$FILES_TO_PROCESS" #Redirect FILES_TO_PROCESS string into read command stdin
    awk -f "./GetFuelSumsByIDForRoute.awk" "$path_to_out/engineTemp.csv"|sort >> "$path_to_out/engine.csv" #Run awk script to sum fuel usage by ID on file containing partial totals of fuel usage for vehicle for route. By summing route fuel usage for vehicle for all routes we get the total fuel used by the vehicle. Sort this output on vehicle ID and append to engine.csv file
    rm "$path_to_out/engineTemp.csv" #Delete temporary engine processing file
    
} 1>>"$PATH_TO_PROCESSING_DIRECTORY/log.txt" 2>&1 #redirect stdout and stderr for function to log.txt  




#Main
#Flags:
#-t : Use testing data subset obtained with filter.sh script

#Arguments: 
#First argument after option flags: File path of processing directory with subfolders /data and /out

#Exit Codes:
#0: No errors on execution
#1: Arguments non-valid format

if [[ $# -gt 2  ]] || [[ $# -lt 1 ]];then
    printf "%s\t$(date)\tERROR: Invalid number of command line arguments\n" "$0">&2        
    exit 1
fi
PATH_TO_PROCESSING_DIRECTORY=""
FILES_TO_PROCESS=""
GetFilesToProcess "$@"
ProcessData
exit 0