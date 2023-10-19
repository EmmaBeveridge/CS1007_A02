#!/usr/bin/env bash

SelectNLargestFiles(){
    #$1: Name of directory containing data subdirectory containing files to filter
    #$2: Number of files to return
    local path_to_data_directory="$1/data"
    local number_of_files=$2
    
    ######TO DO: ERROR HANDLING IF FOLDER HAS LESS THAN N FILES
    largest_file_paths=$(find "$path_to_data_directory" -mindepth 1 -type f -exec ls -S {} + | head -n "$number_of_files")
    while IFS= read -r file_path; do #set internal field separator (IFS) to empty string as default is whitespace - would result in file path with whitespace being split into multiple fields at whitespace so only portion of line file path string up to first whitespace (first field) being assigned to file_path - necessary as file path may contain whitespace.
                                     # -r flag on read stops \ in file paths being interpretted as escape sequences
        basename "$file_path" #Double quoting file path prevents wordsplitting into multiple arguments for basename command (arguments usually delimited by space) -allows for file paths with whitespace to be treated as 1 path
    done <<< "$largest_file_paths" #Double quoting stops wordsplitting into multiple arguments for read command due to whitespace as above
    
    #don't trust ls with file names
}





#Arguments
#$1: Name of directory containing data subdirectory containing files to filter

#####TO DO: CL ARG CHECKING

if [[ $# -ne 1 ]];then
    echo "Usage $0: Invalid number of command line arguments" >&2
    exit 1
fi

SelectNLargestFiles "$1" 5
exit 0


