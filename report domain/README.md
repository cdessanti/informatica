list all connections for a powercenter repository and store the connection details on a 
file called connection_details_for_repository_[repository_name].txt

./list_connections.sh [domain_name] [repository_name] [admin_name] [password]

report basic objects of an Informatica domain, like nodes, services, users or connection
and if user/group details are specifiec with the -ug switch the following files are produced
users_details.txt 
groups_and_roles_details.txt

./report_domain_objects.sh -un=Administrator -pw=[password] -dmn=pwcdt -ug >report_pwcdt.txt
