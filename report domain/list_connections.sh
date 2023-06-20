#!/bin/bash
pmrep connect -r $2 -d $1 -n $3 -x $4 2>&1 >/dev/null
if [ "$?" != "0" ]; then
  echo "cannot connect existing";
  echo "usage: list_connections.sh domain_name repository_name admin_user password"
fi;
connections=$(pmrep listconnections -t | egrep "relational|loader|ftp")
details_file=connection_details_for_repository_$2.txt
if test -f "$details_file"; then
 rm $details_file 2>&1 >/dev/null
fi;
for conn in $connections
do
  IFS=',' read connection_name connection_types database_type <<< $conn
  echo "CONNECTION: "$connection_name" TYPE: "$database_type
  connection_detail=$(pmrep getconnectiondetails -n $connection_name -t relational | egrep -v "Rights|Informatica|success|Invoked|See patents|Completed at")
  echo $connection_detail  >>$details_file
done;