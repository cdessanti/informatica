
domain=domain
username=Administrator
password=password
show_usage_and_exit() {
echo "report_domain_objects.sh -un|--username=[admin user] -pd|--password=[password] -dmn|--domain=[powercenter domain]"
}
getPrivileges() {
for g in $1
do
if [ "$3" == "listGroupPrivileges" ]; then
  object=$(echo $g | cut -f 2 -d '/')
  echo -e "$2:"$object"\nPrivileges:"
  for service in $4
  do
    echo -e "$2:"$object" Service:"$service" Privileges:"
    infacmd.sh $3 -dn $domain -un $username -pd $password -gn $object -sn $service | egrep -v "Command"
  done;
elif [ "$3" == "listUserPrivileges" ]; then
  object=$(echo $g | cut -f 2 -d '/')
  echo -e "$2:"$object" Groups:"
  infacmd.sh listGroupsForUser -dn $domain -un $username -pd $password -eu $object | egrep -v "Command"
  for service in $4
  do
    echo -e "Service:"$service" Privileges:"
    infacmd.sh $3 -dn $domain -un $username -pd $password -eu $object -sn $service | egrep -v "Command"
  done;
else
  echo -e "$2:"$g" Privileges:"
  infacmd.sh $3 -dn $domain -un $username -pd $password -rn "$g" | egrep -v "Command"
fi;
done;
}

getPermissions() {
for g in $1
do
   object=$(echo $g | cut -f 2 -d '/')
   echo -e "$2:"$object"\nPermissions:"
   infacmd.sh $3 -dn $domain -un $username -pd $password  -sdn Native $4 $object | egrep -v "Command"
done;

}
getOptions() {
  options=''
  options_command=''
  for o in $(cat $1)
  do
    if [ "$2" == "GetServiceOption" ]; then
      option=$(infacmd.sh $2 -dn $domain -un $username -pd $password -sn $service -op "$o" | egrep -v "Command")
    else
      option=$(infacmd.sh $2 -dn $domain -un $username -pd $password -sn $service -nn $3 -op "$o" | egrep -v "Command")
    fi
    options=$options"\n$o:"$option
    if [ "$option" != "" ]; then
      options_command=$options_command' -so "'$o'"="'$option'"'
    fi
  done;
  echo -e $options
  echo -e $options_command
}

for i in "$@"; do
  case $i in
    -un|--username)
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
    -h|--help)
        show_usage_and_exit 0
        shift
        ;;
    *)
        show_usage_and_exit 100
        ;;
  esac;
done;

IFS='
'

result=$(infacmd.sh listDomainOptions -dn $domain -un $username -pd $password | grep -v "Command Run Succ")
if [ "$result" == "" ]; then
  echo "Cannot connect to domain "$domain". Check the username you are using has enoug privileges."
  exit -1
fi;
echo "Domain:"$domain
infacmd.sh listDomainOptions -dn $domain -un $username -pd $password | egrep -v "Command"
nodes=$(infacmd.sh listNodes -dn $domain -un $username -pd $password | egrep -v "Command")
node=''
for i in $nodes
do
if [ "$node" == "" ]; then
  node=$i
fi;
echo "Node:"$i
infacmd.sh listNodeOptions -dn $domain -un $username -pd $password -nn $i | egrep -v "Command"
infacmd.sh listNodeResources -dn $domain -un $username -pd $password -nn $i | egrep -v "Command"
infacmd.sh listNodeRoles -dn $domain -un $username -pd $password -nn $i | egrep -v "Command"
done;
services=$(infacmd.sh listServices -dn $domain -un $username -pd $password | egrep -v "Command" | egrep "prs|pis|wsh")
for service in $services
do
echo "Service:"$service
infacmd.sh listServiceNodes -dn $domain -un $username -pd $password -sn $service | egrep -v "Command"
if [[ $service == *"pis"* ]]; then
  getOptions list_of_pis_options.txt GetServiceOption
  getOptions list_of_pis_process_options.txt GetServiceProcessOption $node
elif  [[ $service == *"prs"* ]]; then
  getOptions list_of_prs_options.txt GetServiceOption
elif  [[ $service == *"wsh"* ]]; then
  getOptions list_of_wsh_options.txt GetServiceOption
fi;
done;
groups=$(infacmd.sh listAllGroups -dn $domain -un $username -pd $password | egrep -v "Command")
users=$(infacmd.sh listAllUsers -dn $domain -un $username -pd $password | egrep -v "Command")
roles=$(infacmd.sh listAllRoles -dn $domain -un $username -pd $password | egrep -v "Command")
getPermissions "$users" user listUserPermissions "-eu"
getPrivileges "$users" user listUserPrivileges "$services"
getPermissions "$groups" group listGroupPermissions "-eg"
getPrivileges "$groups" group listGroupPrivileges "$services"
getPrivileges "$roles" role listRolePrivileges "$services"
