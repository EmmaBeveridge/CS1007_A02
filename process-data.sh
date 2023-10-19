#!/usr/bin/env bash

GetFilesToProcess(){
    ##ARGUMENTS:
    ##$1: File path of processing directory with subfolders /data and /out 
    local use_test_files=false
    while getopts 't' flag; do
        case "$flag" in
        t)
            echo $(date)": Using testing data set" >> "$1/log.txt"
            use_test_files=true
            ;;
        ?)
            echo "Usage $0: Invalid flag supplied" 
            exit 1
            ;;
        esac
    done 
    shift "$(($OPTIND -1))" #OPTIND contains index of next argument to be processed by getopts command
                            #When end of options reached (getops returns with exit code != 0), OPTIND set to index of first non-option arg
                            #Use shift command to remove the first strings from positional params list - remove all options processed by getops so now non-option argument can be referred to by $1 variable
                            #Requires script to be called with options before arguments on command line as is bash convention
    PATH_TO_PROCESSING_DIRECTORY="$1"
    if [[ "$use_test_files" = true ]]; then
        FILES_TO_PROCESS=$(./filter.sh "$PATH_TO_PROCESSING_DIRECTORY")
    else
        FILES_TO_PROCESS=$(ls "$PATH_TO_PROCESSING_DIRECTORY"/data)
    fi
    
}



ProcessData(){
    #ARGUMENTS:

    local path_to_data="$PATH_TO_PROCESSING_DIRECTORY/data"
    local path_to_out="$PATH_TO_PROCESSING_DIRECTORY/out"

    touch "$path_to_out/duration.csv"
    printf "route,duration\n" >"$path_to_out/duration.csv"
    
    touch "$path_to_out/engine.csv"
    printf "id,fuel\n" >"$path_to_out/engine.csv"
    
    
    printf ""> "$path_to_out/engineTemp.csv"

    while IFS= read -r route_file_name; do
        
        route_name=${route_file_name%.*}
        mean_duration=$(tail -n +2 < "$path_to_data/$route_file_name"| awk -f "./GetMeanDurationForRoute.awk")
        mean_duration_formatted=$(date -u -d @${mean_duration} +"%T")
        printf "$route_name,$mean_duration_formatted\n" >> "$path_to_out/duration.csv"
        tail -n +2 < "$path_to_data/$route_file_name"| awk -f "./GetFuelSumsByIDForRoute.awk" >> "$path_to_out/engineTemp.csv"
    done <<< "$FILES_TO_PROCESS"

    awk -f "./GetFuelSumsByIDForRoute.awk" "$path_to_out/engineTemp.csv"|sort >> "$path_to_out/engine.csv"
    rm "$path_to_out/engineTemp.csv"




}




#Main
#ARGUMENTS: 
#First argument after option flags: File path of processing directory with subfolders /data and /out

#TO DO: CHECK DIRECTORY EXISTS???




if [[ $# -gt 2  ]] || [[ $# -lt 1 ]];then
    echo "Usage $0: Invalid number of command line arguments" >&2
    exit 1
fi
PATH_TO_PROCESSING_DIRECTORY=""
FILES_TO_PROCESS=""
GetFilesToProcess "$@"
ProcessData
exit 0