#!/usr/bin/env bash

#SetUpDirectory
#Function: Creates working directory for scripts containing log file and subdirectories for downloaded data (/data) and output (/out). If directory with name already exists, it is deleted 
#Arguments:
#$1: File path for working directory to create
SetUpDirectory(){

    local directory_name=$1

    mkdir -p $directory_name
    #If error in making directory, write message to stderr as log file does not exist yet
    if [[ $? -ne 0 ]]; then 
        printf "%s\t$(date)\tERROR :Failed to make directory %s\n" "$0" "$directory_name" >&2 
        exit 2
    fi 

    #Creates log file in new working directory
    printf "%s\t$(date)\tMESSAGE: Log file created in %s\n" "$0" "$directory_name" > "$directory_name/log.txt"

    {
    #Creating subdirectories data, out. Logs warning and deletes if directory already exists.
    for sub_dir in {"data","out"}; do 
        if [ -d "$directory_name/$sub_dir" ];then
            printf "%s\t$(date)\tWARNING: %s already exists. Deleting %s\n" "$0" "$directory_name/$sub_dir" "$directory_name/$sub_dir"
            rm -rf "$directory_name/$sub_dir" 
        fi
        mkdir "$directory_name/$sub_dir" 
    done

    } 1>>"$1/log.txt" 2>&1 #redirect stdout and stderr for block to log.txt

}  

#DownloadData
#Function: Download data files in filelist from URL to directory
#Arguments:
#$1: directory name to which files should be downloaded
#$2: base URL from which to download files
DownloadData(){

    local directory_name=$1
    local base_url=$2

    #Downloading filelist.txt. Output appended to log.txt file, -nv nonverbose flag set. wget command automatically replaces space characters with %20 when accessing URL
    local filelist_url="$base_url/filelist.txt"
    wget -P "$directory_name/data" "$filelist_url"  -nv -a "$directory_name/log.txt"
    if [[ $? -ne 0 ]]; then 
        printf "%s\t$(date)\tERROR :Failed to download filelist.txt from %s\n" "$0" "$base_url"
        exit 3
    fi 


    
    #Downloading files in filelist.txt. Output appended to log.txt file, -nv nonverbose flag set. wget command automatically replaces space characters with %20 when accessing URL NB: Requires each URL to be on separate line with unix line endings to work. Uses -B option pecify a base URL to use to resolve relative file names read from input file given in -i option
    wget -P "$directory_name/data" -i "$directory_name/data/filelist.txt" -B "$base_url"  -nv -a "$directory_name/log.txt"
    if [[ $? -ne 0 ]]; then 
        printf "%s\t$(date)\tERROR :Failed to download file(s) in filelist from %s\n" "$0" "$base_url"
        exit 3
    fi 

    #Deleting filelist.txt file
    rm "$directory_name/data/filelist.txt"

} 1>>"$1/log.txt" 2>&1 #redirect stdout and stderr for function to log.txt




#Main
#Arguments
#$1: directory name to which files should be downloaded
#$2: base URL from which to download files

#Exit Codes:
#0: No errors on execution
#1: Arguments non-valid format
#2: Error in creating directory
#2: File download failed

#Checking argument input
if [[ $# -ne 2 ]];then
    printf "%s\t$(date)\tERROR: Invalid number of command line arguments\n" "$0">&2
    exit 1
fi
root_pattern="^( |/)*$"
blank_pattern="^ *$"
if [[ $1 =~ $root_pattern ]];then
    printf "%s\t$(date)\tWARNING: Working in root directory\n" "$0">&2
fi
if [[ $2 =~ $blank_pattern ]];then
    printf "%s\t$(date)\tERROR: Base URL should not be blank" "$0">&2
    exit 1
fi
#Calling script functions
SetUpDirectory "$1"
DownloadData "$@"
exit 0