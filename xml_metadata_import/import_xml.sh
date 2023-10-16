#!/bin/bash

init() {
    BACKUP_IFS=$IFS
    IFS='
'
    SILENT="false"
    ARCHIVE="false"
    PATH_XML_FILES=/infa_shared/automated_imports
    PATH_ARHCIVED=$PATH_XML_FILES"/archived"
    CONTROL_FILENAME="default_control.xml"
    CONTROL_TEMPLATE="default_control_template.xml"
    FILENAME=""
    START_TIMETSTAMP=$(date +"%Y%m%d_%X_%m_%N")
    status="SUCCESS"
}

show_usage_and_exit() {
  exit_code=$1
  exit_message=$2

  echo -e "import_xml.sh -f|--filename=filename.xml -sf|--source-folder=folder_name -sr|--source-repository=repository_name [-tf|--target-folder=folder_name] [-tr|--target-repository=repository_name] [-cf|--control-filename=control_filename.xml] [-pxf|path-xml-files=/path_to_xml_files] [-s|--silent] [-a|--archive]"
  echo -e "-s|--silent                              run in silent mode"
  echo -e "-a|--archive                             the imported file will be archived and compresssed."
  echo -e "-pxf|--path-xml-files=/path              the path where the medatadat and controlfiles are stored. if not specified the $TMP path will be used"
  echo -e "-f|--filename={filename}.xml             the name of filename containing the xml metadata to import"
  echo -e "-cf|--control-filename={filename}.xml    the name of the controlfile used for the import. if not specified a default controlfile will be used."
  echo -e "-sf|--source-folder=folder_name          the name of the folder in the source repository. Required when the controlfile isn't specified"
  echo -e "-sr|--source-repository=repository_name  the name of source repository. Required when the controlfile isn't specified"
  echo -e "-tf|--target-folder=folder_name          the name of target folder."
  echo -e "-tr|--target-repository=repository_name  the name of target repository."
  

  if [ ! -z "$exit_message" ]; then
    log -e "Error: "$exit_message
  fi;

  exit $exit_code
}

log() {
  if [ "$SILENT" == "false"]; then
    echo -e $(date +"%Y-%m-%d %H:%M:%S ")$1
  fi;
}

error_status() {
  status=$1
  log($1":"$2)
}

substitute_mappings() {
  if [ "$CONTROL_FILENAME" == "default_control.xml" ]; then
  sed "s/***SOURCE_REPOSITORY***/$SOURCE_REPOSITORY/" 
  "s/***SOURCE_FOLDER***/$SOURCE_FOLDER/"
  "s/***TARGET_REPOSITORY***/$TARGET_REPOSITORY/" 
  "s/***TARGET_FOLDER***/$TARGET_FOLDER/" $PATH_XML_FILES"/default/"$CONTROL_TEMPLATE >$PATH_XML_FILES"/import/"$START_TIMETSTAMP/$CONTROL_FILENAME
  end if;
}

connect() {
  username=$1
  password=$2
  domain=$3
  repository=$4
  pmrep connect -r $repository -d $domain -n $username -x $password 2>&1 >/dev/null
  if [ "$?" != "0" ]; then
    log "Error" "Cannot connect to repository "$repository" of domain "$domain;
    return "error"
  fi;
  return "success"
}

import_metadata() {
    path=$1
    file_name=$2
    control_filename=$3
    cmd_status="error"
    if [ ! -d "$path" ]; then
      error_status "Error" "Specified path doesn't exists."
    elif [ ! -f "$file_name" ]; then
      error_status "Error" "Matadata file "$file_name" not found."
    elif [ ! -f "$control_filename" ]; then
      error_status "Error" "Control file "$file_name" not found."
    else
      cmd_status=$(connect $repository $domain $username $password)
      if [ "$cmd_status" == "success" ]; then
        cmd_status=$(pmrep objectimport -i $PATH_XML_FILES/import/$START_TIMETSTAMP/$FILENAME -c $PATH_XML_FILES/import/$START_TIMETSTAMP/$CONTROL_FILENAME )
      fi;
    fi;
    return $cmd_status
}

init

for i in "$@"; do
  case $i in
    -a|--archive)
        ARCHIVE=true
        shift
        ;;
    -s|--silent)
        SILENT=true
        shift
        ;;
    -pxf=*|--path-xml-files=*)
        PATH_XML_FILES=${i#*=}
        shift
        ;;
    -f=*|--filename=*)
        FILENAME=${i#*=}
        shift
        ;;
    -cf=*|--control-filename=*)
        CONTROL_FILENAME=${i#*=}
        shift
        ;;
    -sf=*|--source-folder=folder_name=*)
        SOURCE_FOLDER=${i#*=}
        shift
        ;;
    -sf=*|--source-repository=*)
        SOURCE_REPOSITORY=${i#*=}
        shift
        ;;
    -tf=*|--target-folder*)
        TAGRET_FOLDER=${i#*=}
        shift
        ;;
    -tr=*|--target-repository=*)
        TARGET_REPOSITORY=${i#*=}
        shift
        ;;
    -h|--help)
        show_usage_and_exit 0
        shift
        ;;
    *)
        show_usage_and_exit 100
        ;;
  esac;
done;

# Check for script parameter
if [ -z "$FILENAME" ]; then
  exit_code = 101
  exit_message = "The name of the metadata file is missing."
fi;

if [ -z "$CONTROL_FILENAME" ] && [ -z "$SOURCE_REPOSITORY" ] && [ -z "$SOURCE_FOLDER" ]; then
  exit_code = 101
  exit_message = "\nCannot use the default controlfile when source_repository and source_folders are missing."
fi;

log "Info: Creating import path "$PATH_XML_FILES"/import/"$START_TIMETSTAMP
mkdir -p $PATH_XML_FILES"/import/"$START_TIMETSTAMP

if [ exit_code == "0" ];
  TARGET_REPOSITORY="${TARGET_REPOSITORY:=$SOURCE_REPOSITORY}"
  TARGET_FOLDER="${TARGET_FOLDER:=$SOURCE_FOLDER}"
  cmd_status=$(import_metadata $PATH_XML_FILES $START_TIMETSTAMP $FILENAME $CONTROL_FILENAME)
  if [ "$cmd_status" == "SUCCESS" ]; then
    log "Info: Import of file "$FILENAME" succeded" 
    exit_code=0
  else 
    log "Error: Import of file "$FILENAME" failed with error."
    exit_code=1
  fi;
  if [ "$ARCHIVED" == "true" ]; then
    tar zcvf $PATH_ARHCIVED/$file_name_$START_TIMETSTAMP.tar.gz $PATH_XML_FILES"/import/"$START_TIMETSTAMP/
  fi;
  rm -Rf $PATH_XML_FILES"/import/"$START_TIMETSTAMP
  log "Info: Removed import path. Exiting"
  exit $exit_code
else
  show_usage_and_exit $exit_code "Error: "$exit_message
fi;