#####################################################################################
#
#   Script automatize the migration of all zones from AWS to GCP
#
#   requirements: Linux (of course) - gcloud - cli53
#   Download cli53-linux-amd64 to folder where you want to place your scripts and give permissions to execute chmod +x cli53-linux-amd64
#   cli53 repo: https://github.com/barnybug/cli53
#   before start configure the auth of AWS and GCP - Configure the project to import zones
#   References: 
#   https://cloud.google.com/sdk/gcloud/reference/dns/record-sets/import - 
#   https://cloud.google.com/dns/records#gcloud_1
#   https://github.com/barnybug/cli53
#
#   Made by https://github.com/Alberto-mb/gcp-scripts
#####################################################################################


#!/bin/bash

PWD=`pwd`
ZFILE=all-zones
### LIST ALL ZONES ON AWS
${PWD}/cli53-linux-amd64 l | awk '{ print $2}' | sort -u  > $ZFILE
###CLEAN LIST OF ZONES
sed -i -e '/local./d' -e '/Name/d' $ZFILE

##################################################
# START LOOP FOR EACH ZONE EXPORTED TO $ZFILE
##################################################

for i in $(cat ${ZFILE} )
do

  ################################
  # SET THE NAME OF ZONE
  ################################
  # Set comma as delimiter
  IFS='.'
  #Read the split words into an array based on comma delimiter
  read -a strarr <<< "$i"
          # Print each value of the array by using loop
          NAME=""
          for (( n=0; n < ${#strarr[*]}; n++))
          do
                  m=$(($n +1 ))
          if [ $m -lt ${#strarr[*]} ]
            then
                  NAME="${NAME}${strarr[n]}-"
          else
                  NAME="${NAME}${strarr[n]}"
            fi
          done
  IFS=' '
  FILENAME=${PWD}/zones/${NAME}
  LOG=${PWD}/zones/${NAME}.log
  echo "Start importing $NAME ..."
  echo "Start importing $NAME ..." > $LOG

  ################################
  # CREATE ZONES ON GCP
  ################################

  echo "Creating zone into GCP CLOUD DNS.."

         gcloud dns managed-zones create $NAME \
                 --description="DNS ${i}" \
                 --dns-name=${i} \
                 --visibility=public >> $LOG

  ######################################
  # EXPORT , CLEAN AND IMPORT ZONE ENTRIES
  ######################################
  echo "Exporting and remove flags"...
  ### EXPORT ZONE FROM AWS
  ${PWD}/cli53-linux-amd64 export -f $i > $FILENAME
  ##CLEAN LINES WICH CONTAIN DNS SOA E NS - THESE ENTRIES CANNOT BE IMPORTED TO GCP
  sed -i -e '/AWS/d' -e '/SOA/d' -e '/NS/d' $FILENAME

  echo "Importing file $FILENAME to zone ${NAME}"
  gcloud dns record-sets import $FILENAME --zone-file-format --zone=$NAME >> $LOG
done
##################################################
# END LOOP FOR EACH ZONE EXPORTED TO $ZFILE
##################################################
