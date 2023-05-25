# list all connections for a powercenter repository and store the connection details on a 
# file called connection_details_for_repository_[repository_name].txt

./list_connections.sh rgs_infa_dev prs_ent_dev infaadmin 19almacero

# report basic objects of an Informatica domain, like nodes, services, users or connections

./report_domain_objects.sh -un=Administrator -pw=[password] -dmn=pwcdt -ug >report_pwcdt.txt
