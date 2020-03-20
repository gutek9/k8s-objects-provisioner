#!/bin/bash

LOCK_DIR="/tmp/provisioner.lock"

function lock {
    if [ -e "${LOCK_DIR}" ]; then
        echo "Lock exist. Exitting..."
        exit 1
    fi
    mkdir $LOCK_DIR 2> /dev/null
}

function remove_lock {
    rm -rf $LOCK_DIR
    exit 2
}

trap remove_lock SIGINT
trap remove_lock KILL

function get_data {
    f=$1
    
    objectpath=$( dirname $f )
    objectname=$( echo $objectpath | rev | cut -d "/" -f1 | rev )
}

function deploy_fromfile {
    type=$1
    
    kubectl -n $ns create $type $objectname --from-file=$objectpath
    RESULT=$?

    if [[ $RESULT -ne 0 ]]; then
        kubectl -n $ns delete $type $objectname
        kubectl -n $ns create $type $objectname --from-file=$objectpath
    fi
}

#set -x

workspace=${1:-/src}

lock

# INITIAL LIST and CLONE
cd $workspace

for ns in $( git branch -r | grep -vE 'TEMPLATE|master' | awk -F "/" '{print $2}' ); do
    
    git checkout $ns
    git pull

    oldlist=/tmp/$ns\_oldlist
    find ! -path "./.git*" -type f -exec md5sum "{}" + > $oldlist

done

while true; do
    for ns in $( git branch -r | grep -vE 'TEMPLATE|master' | awk -F "/" '{print $2}' ); do 
    
      oldlist=/tmp/$ns\_oldlist
      newlist=/tmp/$ns\_newlist
     
      git checkout $ns 
      git pull  

      find ! -path "./.git*" -type f -exec md5sum "{}" + > $newlist

      for item in $( comm -1 -3 <(sort /tmp/$ns\_oldlist) <(sort /tmp/$ns\_newlist) | cut -d " " -f3 ); do
        get_data $item

        case "$item" in 
          *deployments*)
             kubectl -n $ns apply -f $item
             ;;
          *secrets*)
             if [[ "$item" == *".yaml" ]]; then
               kubectl -n $ns apply -f $item
             elif [[ "${objectdone[@]}" != $objectpath ]]; then
               deploy_fromfile secret
             fi
             objectdone+=($objectpath)
             ;;
          *configmaps*)
             if [[ "$item" == *".yaml" ]]; then
               kubectl -n $ns apply -f $item
             elif [[ "${objectdone[@]}" != $objectpath ]]; then
               deploy_fromfile configmap
             fi
             objectdone+=($objectpath)
             ;;
          *statefulsets*)
             kubectl -n $ns apply -f $item
             ;;
          *services*)
             kubectl -n $ns apply -f $item
             ;;
           *)
             echo "Unhandled file $item"
             ;;
         esac
      done

      cp $newlist $oldlist
      objectdone=()

    done
  sleep 10
done

remove_lock
