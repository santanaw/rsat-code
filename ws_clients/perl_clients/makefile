################################################################ The
## command necessary to (re-)generate the Stub for ensuring
## compatibility with the Web services

include ${RSAT}/makefiles/util.mk
MAKEFILE=makefile

# SERVER=http://192.54.201.87/rsat
# SERVER=http://192.168.56.101/rsat
SERVER=http://www.rsat.eu
# SERVER=http://rsat-tagc.univ-mrs.fr/rsat
# SERVER=http://rsat.ulb.ac.be/rsat
# SERVER=http://139.124.66.4/rsat
# SERVER=http://liv.bmc.uu.se/rsa-tools
# SERVER=http://bongcam1.hgen.slu.se/rsat
# SERVER=http://tagc.univ-mrs.fr/rsa-tools
# SERVER=http://embnet.ccg.unam.mx/rsa-tools
# SERVER=http://localhost/rsat
SERVERS= \
	http://www.rsat.eu \
	http://prokaroyte.rsat.eu \
	http://fungi.rsat.eu \
	http://plants.rsat.eu \
	http://metazoa.rsat.eu \
	http://protists.rsat.eu \
	http://teaching.rsat.eu \
	http://training.rsat.eu \
	http://rsat.ulb.ac.be/rsat \
	http://embnet.ccg.unam.mx/rsa-tools \
	http://pedagogix-tagc.univ-mrs.fr/rsat \
	http://nexus.hgen.slu.se/rsa-tools
SERVERS_TO_CHECK = \
	http://tagc.univ-mrs.fr/rsa-tools \
	http://localhost/rsat

list_servers:
	@echo "SERVERS	${SERVERS}"
	@echo "SERVER	${SERVER}"
	@echo "WSDL_URL	${WSDL_URL}"
	@echo "RSAT_WS	${RSAT_WS}"

stub_param:
	@echo "Parameters for generating the stub"
	@echo "SERVERS	${SERVERS}"
	@echo "SERVER	${SERVER}"
	@echo "WSDL_URL	${WSDL_URL}"

WSDL_URL=${SERVER}/web_services/RSATWS.wsdl
stub:
	@echo
	@echo "Generating stub for server"
	@echo "	SERVER=${SERVER}"
	@echo "	WSDL_URL=${WSDL_URL}"
	perl ./wsdl2perl.pl -b RSATWS ${WSDL_URL}
	@echo "Generated stub for server"
	@echo "	SERVER=${SERVER}"
	@echo "	WSDL_URL=${WSDL_URL}"

stub_test:
	perl ./convert_matrix_soap_wsdl_2.pl 


nostub_test:
	@echo "Testing web services without stub	${RSAT_WS}"
	perl ./supported-organisms_client_nostub_wsdl.pl ${RSAT_WS}

nostub_test_all_servers:
	@for server in ${SERVERS}; do \
		${MAKE} RSAT_WS=$${server} nostub_test; \
	done

