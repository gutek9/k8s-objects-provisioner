# #check env FORCE_UPDATE lockfile
# #if exists run prov for all
# #order:
# #namespaces
# #configmaps
# #secrets
# #labels
# #deploymets
#
# #!/bin/bash
# . /provisioners/functions
#
# func_initialize $PROV_TYPE $DEPLOYMENT_DIR
#
# cleanup ()
# {
#   kill -s SIGTERM $!
#   exit 0
# }
# trap cleanup SIGINT SIGTERM
#
# if ( set -o noclobber; echo $PROV_TYPE > "$lockfile_force_update") 2> /dev/null; then
#   trap 'rm -f "$lockfile_force_update"; exit $?' INT TERM EXIT
# fi
#
#
# while [ 1 ]
# do
#   sleep $[ ( $RANDOM % 20 )  + 1 ]s &
#   wait $!
#
#   #namespaces
#   if ( set -o noclobber; echo $PROV_TYPE > "$lockfile") 2> /dev/null; then
#     trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
#
#     func_apply_on_changed_files $NS_DIR
#
#     # clean up after yourself, and release your trap
#     rm -f "$lockfile"
#     trap - INT TERM EXIT
#   else
#     date=$(date --iso-8601=seconds)
#     echo "$date Lock Exists: $lockfile owned by $(cat $lockfile)"
#   fi
#
#   #configmaps
#   ######
#   while [ ! -f /tmp/configmaplist.txt ]
#   do
#     sleep 2
#     echo "There is no file with configmap list yet"
#     ###create configmaplist with hashes, avoid deleteing pods during startup
#     dir=/src/$CONFIGMAPS_DIR
#     nsList=$(ls -d $dir*/*/*/)
#     # echo $nsList
#
#     for i in $nsList
#     do
#       hash=$(find $i -type f -name "*" -not -path "*.git*" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{ print $1 }')
#       echo "$hash  $i  " >> /tmp/configmaplist.txt
#     done
#
#   done
#
# ##configmap prov process
# ############ configmap
# dir=/src/$CONFIGMAPS_DIR
# nsList=$(ls -d $dir*/*/*/)
# # echo $nsList
#
# #create list with hashes of configmap dirs inside on ns dirs
# for i in $nsList
# do
#   hash=$(find $i -type f -name "*" -not -path "*.git*" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{ print $1 }')
#   # echo   $i
#   # echo $hash
#   echo "$hash  $i  " >> /tmp/configmaplist.new.txt
# done
# comm -1 -3 <(sort /tmp/configmaplist.txt) <(sort /tmp/configmaplist.new.txt) > /tmp/configmaplist.process.txt
#
# #delete pods, which uses changed configmap. wait after delete 60s
# while read secline
# do
#
#   SUBSTRING=$(echo $secline|  cut -d' '  -f2)
#   secName=$(basename $SUBSTRING)
#   NS=$(basename $(dirname $SUBSTRING))
#   date=$(date --iso-8601=seconds)
#   echo "$date configmap $secName in $NS was changed. It will be deleted"
#   kubectl --namespace=$NS delete configmap $secName
#   sleep 1
#   date=$(date --iso-8601=seconds)
#   echo "$date configmap $secName in $NS will be created"
#   kubectl --namespace=$NS create configmap  $secName --from-file=$SUBSTRING
#
#   #generic solution
#   podlist=$(kubectl --namespace=$NS get pods -o json |  jq --arg secret $secName '.items[] | select(.spec.volumes[].configMap.name == $secret).metadata.name')
#
#   for i in $podlist
#   do
#     echo "pod list using configmap $secName is $podlist "
#     echo ""
#     echo "currently processed pod $i"
#     i=$(echo "$i" | tr -d '"')
#     date=$(date --iso-8601=seconds)
#     echo "$date Deleting pod $i in namespace $NS using configmap $secName "
#     kubectl --namespace=$NS delete pod    $i
#     sleep 6
#
#   done
#
# done < /tmp/configmaplist.process.txt
#
# mv /tmp/configmaplist.new.txt  /tmp/configmaplist.txt
#
#   #secrets
#   ############ Secrets
#   dir=/src/$SECRETS_DIR
#   nsList=$(ls -d $dir*/*/*/)
#   # echo $nsList
#
#   #create list with hashes of secrets dirs inside on ns dirs
#   for i in $nsList
#   do
#     hash=$(find $i -type f -name "*" -not -path "*.git*" -exec md5sum {} + | awk '{print $1}' | sort | md5sum | awk '{ print $1 }')
#     # echo   $i
#     # echo $hash
#     echo "$hash  $i  " >> /tmp/secretlist.new.txt
#   done
#   comm -1 -3 <(sort /tmp/dirlist.txt) <(sort /tmp/secretlist.new.txt) > /tmp/secretlist.process.txt
#
#   #run apply patch on deployments, which uses changed secrets. this triggers rolling update
#   while read secline
#   do
#
#     SUBSTRING=$(echo $secline|  cut -d' '  -f2)
#     # echo "SUBSTRING"$SUBSTRING
#     echo ""
#     secName=$(basename $SUBSTRING)
#     # echo "secName"$secName
#     echo ""
#     NS=$(basename $(dirname $SUBSTRING))
#     # echo "ns"$NS
#     echo ""
#     date=$(date --iso-8601=seconds)
#     echo "$date Secret $secName in $NS was changed. It will be deleted"
#     kubectl --namespace=$NS delete secret $secName
#     sleep 1
#     date=$(date --iso-8601=seconds)
#     echo "$date Secret $secName in $NS will be created"
#     kubectl --namespace=$NS create secret generic $secName --from-file=$SUBSTRING
#
#
#
#     # solution for deployment
#     podlist=$(kubectl --namespace=$NS get deployment -o json |  jq --arg secret $secName '.items[] | select(.spec.template.spec.volumes[]?.secret.secretName == $secret).metadata.name')
#
#     for i in $podlist
#     do
#       i=$(echo "$i" | tr -d '"')
#       date=$(date --iso-8601=seconds)
#       echo "$date kubectl patch on deployment $i in namespace $NS using secret $secName "
#       kubectl --namespace=$NS patch deployment $i -p   "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"secretUpdate\":\"`date +'%s'`\"}}}}}"
#
#       sleep 1
#
#     done
#
#   done < /tmp/secretlist.process.txt
#
#   mv /tmp/secretlist.new.txt  /tmp/dirlist.txt
#   #labels
# #  func_apply_on_changed_files $DEPLOYMENT_DIR/labels
#   #deploymets
#   func_apply_on_changed_files $DEPLOYMENT_DIR
#
#
# done
