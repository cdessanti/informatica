#!/bin/bash

show_usage_and_exit() {
  echo "create_service.sh"
  echo "common parameters for repository and integration service type"
  echo "-un|--username=[admin user] -pw|--password=[password] -dmn|--domain=[domain name]"
  echo "-nn|node_name=[node name] [-bn=|--backup-nodes]=[backup nodes] -sd|--service-disabled"
  echo "-st|--service_type=[repository|integration] --service_name=[name of the service] -ln|--license_name=[licence name] -cp|--code_page=[code page of service]"
  echo "parameters needed for repository only"
  echo "-dba|--db-address=[alias for the database] -dbu|--db-user=[database username] -dbp|--db-password=[database password]"
  echo "parameters needed for integration only"
  echo "-po|--process_options=[process options] -rn|--repository_name=[associated repository name]"
}

for i in "$@"; do
  case $i in
    -un=*|--username=*)
        username=${i#*=}
        shift
        ;;
    -pw=*|--password=*)
        password=${i#*=}
        shift
        ;;
    -dmn=*|--domain=*)
        domain=${i#*=}
        shift
        ;;
    -nn=*|--node-name=*)
        node_name=${i#*=}
        shift
        ;;
    -bn=*|--backup-nodes=*)
        backup_nodes=${i#*=}
        shift
        ;;
    -dba=*|--db-address=*)
        db_address=${i#*=}
        shift
        ;;
    -dbs=*|--db-service=*)
        db_service=${i#*=}
        shift
        ;;
    -dbu=*|--db-user=*)
        db_user=${i#*=}
        shift
        ;;
    -dbp=*|--db-password=*)
        db_password=${i#*=}
        shift
        ;;
    -st=*|--service-type=*)
        service_type=${i#*=}
        shift
        ;;
    -sn=*|--service-name=*)
        service_name=${i#*=}
        shift
        ;;
    -ln=*|--license-name=*)
        license_name=${i#*=}
        shift
        ;;
    -cp=*|--code-page=*)
        code_page=${i#*=}
        shift
        ;;
    -rn=*|--repository-name=*)
        repository_name=${i#*=}
        shift
        ;;
    -h|--help)
        show_usage_and_exit 0
        shift
        ;;
    -so=*|--service-options=*)
        service_options=${i#*=}
        shift
        ;;
    -po=*|--process-options=*)
        process_options=${i#*=}
        shift
        ;;
    -t|--test)
        test_mode="true"
        shift
        ;;
    -sd|--service-disabled)
        service_disabled="true"
        shift
        ;;
    *)
        show_usage_and_exit 100
        ;;
  esac;
done;

print_error_and_exit() {
  echo $1
  exit 1
}

check_params() {
  if [ "$service_type" == "repository" ] ; then
    if [ -z ${db_address+x} ] || [ -z ${db_user+x} ] || [ -z ${db_password+x} ]; then
      print_error_and_exit "database parameters not set. exiting"
    fi
  elif [ "$service_type" == "integration" ] ; then
    if [ -z ${repository_name+x} ]; then
      print_error_and_exit "associated repository name not set. exiting"
    fi
  fi
  if [ -z ${username+x} ] || [ -z ${password+x} ] | [ -z ${domain+x} ]; then
    print_error_and_exit "domain name, user or password not set. exiting"
  fi;
  if [ -z ${node_name+x} ] || [ -z ${service_name+x} ] || [ -z ${service_type+x} ]; then
    print_error_and_exit "node name, service name, service options or service type not set. exiting"
  fi;
  if [ "$service_type" != "repository" ] && [ "$service_type" != "integration" ]; then
     print_error_and_exit "service type '"$service_type"' unknown, select repository or integration. existing"
  fi
}

build_command() {
  common_options=" -dn "$domain" -un "$username" -pd "$password" -sn "$service_name"  -nn "$node_name" -ln "$license_name
  if [ "$backup_nodes" != "" ]; then 
    common_options=$common_options" -bn "$backup_nodes
  fi

  if [ "$service_type" == "repository" ]; then
    command="createRepositoryService "
    command=$command" "$common_options" -so CodePage="$code_page" ConnectString="$db_address" DBPassword="$db_password" DatabaseType=Oracle DBUser="$db_user
  elif [ "$service_type" == "integration" ]; then
    command="createIntegrationService"
    command=$command" "$common_options" -rs "$repository_name" -ru "$username" -rp "$password" -po codepage_id="$code_page
    if [ "$process_options" != "" ]; then
      command=$command" "$process_options
    fi
  fi
  if [ "$service_options" != "" ]; then
    command=$command" -so "$service_options
  fi;
  if [ "$service_disabled" == "true" ]; then
    command=$command" -sd "
  fi;
  echo $command
}

check_params
command=$(build_command)
if [ "$test_mode" == "true" ]; then
  echo "infacmd.sh "$command
else
  infacmd.sh $command
fi  

