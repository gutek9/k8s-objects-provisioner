#!/bin/bash
echo "Provisioner for $PROV_TYPE is starting.."
echo ""

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

#wait until secretlist fill be created
while [ ! -f /tmp/secretlist.txt ]
do
  sleep 1
  echo "There is no file with secrets list yet"
  ###create secretlist with hashes, avoid deleteing pods during startup
  dir=/srcsecrets/$SECRETS_DIR
  nsList=$(ls -d $dir*/*/*/)
  # echo $nsList

  for i in $nsList
    do
    hash=$(find $i -type f -name "*" -not -path "*.git*" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{ print $1 }')
    echo "$hash  $i  " >> /tmp/secretlist.txt
    done

done

#avoid deleteing pods during startup
date=$(date --iso-8601=seconds)
echo "Initial list was created at $date"

###run provisioning  process
while [ 1 ]
do
    sleep 1 &
    wait $!

    ############ Secrets
    dir=/srcsecrets/$SECRETS_DIR
    nsList=$(ls -d $dir*/*/*/)
    # echo $nsList

    #create list with hashes of secrets dirs inside on ns dirs
    for i in $nsList
      do
      hash=$(find $i -type f -name "*" -not -path "*.git*" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{ print $1 }')
      # echo   $i
      # echo $hash
      echo "$hash  $i  " >> /tmp/secretlist.new.txt
      done
      comm -1 -3 <(sort /tmp/secretlist.txt) <(sort /tmp/secretlist.new.txt) > /tmp/secretlist.process.txt

      #run apply patch on deployments, which uses changed secrets. this triggers rolling update
      while read secline
      do

        SUBSTRING=$(echo $secline|  cut -d' '  -f2)
        # echo "SUBSTRING"$SUBSTRING
        echo ""
        secName=$(basename $SUBSTRING)
        # echo "secName"$secName
        echo ""
        NS=$(basename $(dirname $SUBSTRING))
        # echo "ns"$NS
        echo ""
        date=$(date --iso-8601=seconds)
        echo "$date Secret $secName in $NS was changed. It will be deleted"
        kubectl --namespace=$NS delete secret $secName
        sleep 1
        date=$(date --iso-8601=seconds)
        echo "$date Secret $secName in $NS will be created"
        kubectl --namespace=$NS create secret generic $secName --from-file=$SUBSTRING



        # solution for deployment
        podlist=$(kubectl --namespace=$NS get deployment -o json |  jq --arg secret $secName '.items[] | select(.spec.template.spec.volumes[].secret.secretName == $secret).metadata.name')

          for i in $podlist
             do
             i=$(echo "$i" | tr -d '"')
             date=$(date --iso-8601=seconds)
             echo "$date kubectl patch on deployment $i in namespace $NS using secret $secName "
             kubectl --namespace=$NS patch deployment $i -p   "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"secretUpdate\":\"`date +'%s'`\"}}}}}"

             sleep 1

             done

      done < /tmp/secretlist.process.txt

      mv /tmp/secretlist.new.txt  /tmp/secretlist.txt


done
