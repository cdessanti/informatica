#!/bin/bash
function show_usage {
  echo "usage: list_connections.sh domain_name repository_name admin_user password [filter]"
}
# if [ "$*" != "4" ]; then
#   show_usage
# fi;
pmrep connect -r $2 -d $1 -n $3 -x $4 2>&1 >/dev/null
if [ "$?" != "0" ]; then
  echo "cannot connect exiting";
  show_usage
fi;
if [ "$5" != "" ]; then
  filter=$5
else
  filter='.*'
fi;

connections=$(pmrep listconnections -t | egrep "relational|loader|ftp" | egrep $filter )
details_file=connection_details_for_repository_$2.txt
if test -f "$details_file"; then
 rm $details_file 2>&1 >/dev/null
fi;
for conn in $connections
do
  IFS=',' read connection_name connection_type database_type <<< $conn
  echo "CONNECTION: "$connection_name" TYPE: "$database_type
  connection_detail=$(pmrep getconnectiondetails -n $connection_name -t $connection_type | egrep -v "Rights|Informatica|success|Invoked|See patents|Completed at")
  echo $connection_detail  >>$details_file
done;
