#!/bin/bash

show_usage_and_exit() {
  echo "install_silent.sh -un|--username=[admin user] -pd|--password=[password] -dmn|--domain=[domain name] -sn|-server-name=[domain server name] -nn|node_name=[node name] -f|file-name=[template file name]"
  exit $1
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
    -f=*|--file_name=*)
        template_filename=${i#*=}
        shift
        ;;
    -sn=*|--server-name=*)
        server_name=${i#*=}
        shift
        ;;
    -lsn=*|--local-server-name=*)
        local_server_name=${i#*=}
        shift
        ;;
    -nn=*|--node-name=*)
        node_name=${i#*=}
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
    -m=*|--mode=*)
        mode=${i#*=}
        shift
        ;;
    -h|--help)
        show_usage_and_exit 0
        shift
        ;;
    -ie|--installation-environment=*)
        environment=${i#*=}
        shift
        ;;
    *)
        show_usage_and_exit 100
        ;;
  esac;
done;

check_template_file() {
  if [ ! -f "$1" ]; then
    echo "The template file $1 doesn't exists. Exiting"
    exit 1
  fi;
}

#DOMAIN_NAME=###DomainName###
#DOMAIN_HOST_NAME=###DomainHostName###
#NODE_NAME=###NodeNam###
#DOMAIN_USER=###AdminUser###
#DOMAIN_PSSWD=###DomainPsswd###
#DOMAIN_CNFRM_PSSWD=###DomainPsswd###
#JOIN_NODE_NAME=###NodeName###
#JOIN_HOST_NAME=###DomainHostName###
#DB_SERVICENAME=###DBServiceName###
#DB_ADDRESS=###DBAddress###
#DB_UNAME=###UserName###
#DB_PASSWD=###UserPassword###

replace_value_template() {
  cat $template_filename | sed "s/###GatewayHostName###/"$server_name"/g"|sed "s/###DomainName###/"$domain"/g"|sed "s/###NodeName###/"$node_name"/g" \
   | sed "s/###AdminUser###/"$username"/g" | sed "s/###DomainPsswd###/"$password"/g" | sed "s/###DBServiceName###/"$db_service"/g" \
   | sed "s/###Env###/"$environment"/g" | sed "s/###HostName###/"$local_server_name"/g" \
   | sed "s/###DBAddress###/"$db_address"/g" | sed "s/###UserName###/"$db_user"/g" | sed "s/###UserPassword###/"$db_password"/g" > SilentInput.properties
}

check_params() {
  if [ "$mode" == "create_domain" ] || [ "$mode" == "join_domain" ]; then
    if [ -z ${db_service+x} ] || [ -z ${db_address+x} ] || [ -z ${db_user+x} ] || [ -z ${db_password+x} ]; then
      echo "database parameters not set. exiting"
      exit 1
    fi
  fi
  if [ "$mode" == "join_worker" ] || [ "$mode" == "join_domain" ]; then
    if [ -z ${local_server_name+x} ]; then
      echo "local server name not set. exiting"
      exit 1
    fi
  fi;
  echo "check username"
  if [ -z ${username+x} ] || [ -z ${password+x} ] | [ -z ${domain+x} ]; then
    echo "domain name, user or password not set. existing"
    exit 1
  fi;

  if [ -z ${template_filename+x} ] || [ -z ${mode+x} ] || [ -z ${environment+x} ]; then
    echo "filename, environment or mode not set. existing"
    exit 1
  fi;
}
 
check_params
replace_value_template

echo "Unsetting INFA variable for install"
unset  INFA_HOME INFA_NODE_NAME INFA_DOMAINS_FILE
