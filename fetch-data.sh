#!/usr/bin/env bash


SetUpDirectory(){

    local directory_name=$1
    mkdir -p $directory_name
    touch $directory_name/log.txt #should log.txt be cleared if it already exists?
    echo "" > $directory_name/log.txt
    #Creating subdirectories data, out. Logs message and deletes if already exist
    for sub_dir in {"data","out"}; do 
        if [ -d "$directory_name/$sub_dir" ];then
            echo $(date)" : WARNING: $directory_name/$sub_dir already exists. Deleting $directory_name/$sub_dir" >> "$directory_name/log.txt"
            rm -rf "$directory_name/$sub_dir" 2>&1 | tee "$directory_name/log.txt" #pipe stdout and stderr to log file
        fi
        mkdir "$directory_name/$sub_dir" 
    done

}


DownloadData(){

    #$1: directory name to which files should be downloaded
    #$2: base URL from which to download files
    local directory_name=$1
    local base_url=$2

    #Downloading filelist.txt
    #Errors appended to log.txt file
    local filelist_url="$base_url/filelist.txt"
    wget -P "$directory_name/data" $filelist_url  -nv -a "$directory_name/log.txt"
    

    
    #Downloading files in filelist.txt
    #Errors appended to log.txt file
    #wget command automatically replaces space characters with %20 when accessing URL
    
    ####TO DO HANDLE NON-ZERO EXIT CODES


    wget -P "$directory_name/data" -i "$directory_name/data/filelist.txt" -B "$base_url"  -nv -a "$directory_name/log.txt"
   
    #Deleting filelist.txt file
    rm "$directory_name/data/filelist.txt"


 ####ENDREGION
}


####TO DO
#maybe check formats and give messages e.g. too few, too many cl arguments
#NEED TO CHECK ARGS NOT BLANK!!!
#Esacpe any spaces in URL provided??


#Arguments
#$1: directory name to which files should be downloaded
#$2: base URL from which to download files

if [[ $# -ne 2 ]];then
    echo "Usage $0: Invalid number of command line arguments" >&2
    exit 1
fi

root_pattern="^( |/)*$"
blank_pattern="^ *$"
if [[ $1 =~ $root_pattern ]];then
    echo $(date)"WARNING: Working in root directory" 
fi
if [[ $2 =~ $blank_pattern ]];then
    echo "Usage $0: Base URL should not be blank" >&2
    exit 1
fi

SetUpDirectory "$1"
DownloadData "$@"