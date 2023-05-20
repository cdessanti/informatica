#!/bin/bash

init() {
    BACKUP_IFS=$IFS
    IFS='
'
    PATH_SCORECARD=""
    PATH_PROFILE=""
    FILE_PRF_SCC=""
    BULK_MODE=true
    PROFILE_NAME=""
    SCORECARD_NAME=""
}

show_usage_and_exit() {
  exit_code=$1
  error_message=$2

  echo -e "bulk mode  : run_profiling_and_scorecard.sh -b|--bulk-mode -pp|--path-profiling=project_name/path -ps|--path-scorecard=project_name/path -csv|--file-csv=filename "
  echo -e "single mode: run_profiling_and_scorecard.sh -s|--single-mode -pp|--path-profiling=project_name/path -ps|--path-scorecard=project_name/path -pn|--profile-name=profile_name -sn--scorecard-name=scorecard_name"
  echo -e "-b|--bulk-mode                      read the profile and scorecard names from a csv file specified with the parameter -csv|--file-csv."
  echo -e "-s|--single-mode                    run the profile and scorecard specified with -pn|--profile-name and -sc|--scorecard-name parameters"
  echo -e "-pp|--path-profiling=prj_name/path  the path to the profile objects in the project e.g. project/profilings/"
  echo -e "-ps|--path-scorecard=prj_name/path  the path to the scorecard objects in the project e.g. project/scorecards/"
  echo -e "-csv|--file-csv=/path/file.csv       the file name in csv format containing a list of propfiles and scorecards to run
                                            with the format EXECUTE,PROFILE_NAME,SCORECARD_NAME. EXECUTE can be t or F.
                                            this parameter is needed in bulk mode only"
  echo -e "-pn|--profile-name=profile_name     the name of the profile to run in single mode"
  echo -e "-sn|--scorecard-name=scorecard_name the name of the scorecard to run in single mode"

  if [ ! -z "$error_message" ]; then
    echo -e "Error: "$error_message
  fi;

  exit $exit_code
}


return_status() {
  command_output=$1
  job_status=$(echo $command_output | cut -f 1 -d " ")
  if [ "$job_status" != "SUCCESS" ]; then
      job_status="FAILURE"
  fi;
  echo $job_status
}

error_status() {
    message="Job $profile_name WITH $scorecard_name"
    if [ "$1" == "SUCCESS" ]; then
        echo -e $message" Succeded,SUCCESS"
    elif [ "$1" == "SKIPPED" ]; then
        echo -e $message" Skipped,SKIP"
    else
        echo -e $message" Failed,FAIL,"$cmd_status
    fi;
}

run_profile_and_scorecard() {
    profile_name=$1
    scorecard_name=$2
    cmd_status=$(infacmd.sh ps execute -dn $PWC_DOMAIN -un $PWC_USER -msn $PWC_MRS -dsn $PWC_DIS -ot profile -opn $PATH_PROFILE"/"$profile_name -w true )
    cmd_status=$(echo $cmd_status | cut -f 2 -d "=")
    if [ "$(return_status $cmd_status)" == "SUCCESS" ]; then
        cmd_status=$(infacmd.sh ps getExecutionStatus -dn $PWC_DOMAIN -un $PWC_USER -msn $PWC_MRS -dsn $PWC_DIS -ot profile -opn $PATH_PROFILE"/"$profile_name)
        if [ "$(return_status $cmd_status)" == "SUCCESS" ]; then
            cmd_status=$(infacmd.sh ps execute -dn $PWC_DOMAIN -un $PWC_USER -msn $PWC_MRS -dsn $PWC_DIS  -ot scorecard -opn $PATH_SCORECARD"/"$scorecard_name -w true)
            cmd_status=$(echo $cmd_status |  cut -f 2 -d "=")
            if [ "$(return_status $cmd_status)" == "SUCCESS" ]; then
                error_status "SUCCESS"
            else
                error_status
            fi;
        else
            error_status
        fi;
    else
        error_status
    fi;
}

init

for i in "$@"; do
  case $i in
    -b|--bulk_mode)
        BULK_MODE=true
        shift
        ;;
    -csv=*|--file-csv=*)
        FILE_PRF_SCC=${i#*=}
        shift
        ;;
    -pp=*|--path-profile=*)
        PATH_PROFILE=${i#*=}
        shift
        ;;
    -ps=*|--path-scorecard=*)
        PATH_SCORECARD=${i#*=}
        shift
        ;;
    -s|--single-mode)
        BULK_MODE=false
        shift
        ;;
    -pn=*|--profile-name=*)
        PROFILE_NAME=${i#*=}
        shift
        ;;
    -sn=*|--scorecard-name=*)
        SCORECARD_NAME=${i#*=}
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

    if [ -z "$PATH_PROFILE" ] || [ -z "$PATH_SCORECARD" ]; then
        show_usage_and_exit -1 "\033[1mMissing the path of profiling and/or the scorcards.\033[0m"
    elif [ "$BULK_MODE" == true ]; then
        if [ -z "$FILE_PRF_SCC" ]; then
            show_usage_and_exit -1 "\033[1mMissing the csv file.\033[0m"
        fi;
    elif [ "$BULK_MODE" == false ]; then
        if [ -z "$PROFILE_NAME" ] || [ -z "$SCORECARD_NAME" ]; then
            show_usage_and_exit -1 "\033[1mMissing the profile or scorecard name to run.\033[0m"
        fi;
    fi;

if [ "$BULK_MODE" == true ]; then
    if [ -f "$FILE_PRF_SCC" ]; then
        while IFS="," read -r run_job profile_to_run scorecard_to_run remaing_scorecards
        do
            if [ "$run_job" == "T" ]; then
                run_profile_and_scorecard $profile_to_run $scorecard_to_run
            else
                error_status "SKIPPED"
            fi;
        done < $FILE_PRF_SCC
    else
        echo -e "Fatal: \033[1mCannopt open the csv file '"$FILE_PRF_SCC"' for reading."
                "Check if the file exists and you have the permission to open it.\033[0m"
   fi;
else
    run_profile_and_scorecard $PROFILE_NAME $SCORECARD_NAME
fi;