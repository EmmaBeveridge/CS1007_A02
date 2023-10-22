#!/usr/bin/env bash

#SelectNLargestFiles
#Function: Find file names of the N largest files in the /data subfolder of the named directory
#Arguments
#$1: Name of directory containing data subdirectory containing files to filter
#$2: Number of files to return
SelectNLargestFiles(){
    
    local path_to_data_directory="$1/data"
    local number_of_files=$2
    
    #Check if /data directory exists
    if [ ! -d "$path_to_data_directory" ];then
        if [ -f "$1/log.txt" ];then #Write error message to log file if it exists
            printf "%s\t$(date)\tERROR: %s does not exist." "$0" "$path_to_data_directory" >> "$1/log.txt"
            exit 2
        else #Write error message to stderr if no log file found
            printf "%s\t$(date)\tERROR: %s does not exist." "$0" "$path_to_data_directory" >&2
            exit 2
        fi
    fi

    #Find largest files in directory
    largest_file_paths=$(find "$path_to_data_directory" -mindepth 1 -type f -exec ls -S {} + | head -n "$number_of_files")

     
    #Handle if too few files found in directory
    if [ $(echo $largest_file_paths|wc -w) -ne $number_of_files ]; then
        printf "%s\t$(date)\tERROR: %s does not contain %s files." "$0" "$path_to_data_directory" "$number_of_files" >> "$1/log.txt"
        exit 2
    fi

    {
    printf "%s\t$(date)\tMESSAGE: Selected largest files:\n" "$0" >> "$1/log.txt"    
    while IFS= read -r file_path; do #set internal field separator (IFS) to empty string as default is whitespace - would result in file path with whitespace being split into multiple fields at whitespace so only portion of line file path string up to first whitespace (first field) being assigned to file_path - necessary as file path may contain whitespace.
                              # -r flag on read stops \ in file paths being interpretted as escape sequences
        basename "$file_path" | tee -a "$1/log.txt" #Double quoting file path prevents wordsplitting into multiple arguments for basename command (arguments usually delimited by space) -allows for file paths with whitespace to be treated as 1 path
                                                    #tee off output to log file
    done <<< "$largest_file_paths" #Double quoting stops wordsplitting into multiple arguments for read command due to whitespace as above
    } 2>>"$1/log.txt" #redirect stderr for block to log.txt
}




#Main
#Arguments
#$1: Name of directory containing data subdirectory containing files to filter

#Exit Codes:
#0: No errors on execution
#1: Arguments non-valid format
#2: Cannot find data files


if [[ $# -ne 1 ]];then
    printf "%s\t$(date)\tERROR: Invalid number of command line arguments\n" "$0">&2        
    exit 1
fi

SelectNLargestFiles "$1" 5
exit 0


