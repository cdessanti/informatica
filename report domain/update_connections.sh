#!/bin/bash
pmrep connect -r $2 -d $1 -n $3 -x $4 2>&1 >/dev/null
if [ "$?" != "0" ]; then
  echo "cannot connect existing";
  echo "usage: list_connections.sh domain_name repository_name admin_user password"
fi;
connections=$(pmrep listconnections -t | egrep "relational")
for conn in $connections
do
  IFS=',' read conn_name conn_type database_type <<< $conn
  actual_cs=$(pmrep getconnectiondetails -n "$conn_name" -t relational | grep "Connect String" | cut -f 2 -d '=')  
  result=$(pmrep updateconnection -t $database_type -d $conn_name -c $actual_cs$5 | egrep "updateconnection completed successfully")
  if [ "$result" == "updateconnection completed successfully." ]; then
    echo "The connection "$conn_name" has been updated. The new Connect String is: "$actual_cs$5
  fi;
done;