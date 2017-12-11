#!/bin/bash

function get_data {
                f=$1
                ns=$( echo $f | cut -d "/" -f3 )
                if [[ $f == *"rcs"* ]]; then
                        pod=$( echo $f | cut -d "/" -f5 | cut -d "." -f1)
                else 
                        pod=$( echo $f | cut -d "/" -f4 )
                fi
}

function deploysecrets {
                local sec=""        
                local seclist=""

                for sec in $( find secrets/$ns/$pod/ -type f ); do
                        seclist="--from-file=$sec $seclist"
                done
                kubectl -n $ns create secret generic $pod $seclist
                RETURN=$?
        
                if [[ $RETURN -eq 1 ]]; then
                        kubectl -n $ns delete secret $pod
                        kubectl -n $ns create secret generic $pod $seclist

                        sleep 0.5

                        kubectl -n $ns patch deployment $pod -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"secretUpdate\":\"`date +'%s'`\"}}}}}"

                elif [[ $RETURN -eq 0 ]]; then
                        kubectl -n $ns patch deployment $pod -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"secretUpdate\":\"`date +'%s'`\"}}}}}"
                else
                        echo "UNKNOWN ERROR DURING SECRETS APPLY. ERROR $RETURN"
                fi
}

function deployconfigmap {
                local sec=""
                local seclist=""

                for sec in $( find configmaps/$ns/$pod/ -type f ); do
                        seclist="--from-file=$sec $seclist"
                done
                kubectl -n $ns create configmap $pod $seclist
                RETURN=$?
        
                if [[ $RETURN -eq 1 ]]; then
                        kubectl -n $ns delete configmap $pod
                        kubectl -n $ns create configmap $pod $seclist

                        sleep 0.5

                        kubectl -n $ns patch deployment $pod -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"configmapUpdate\":\"`date +'%s'`\"}}}}}"

                elif [[ $RETURN -eq 0 ]]; then
                        kubectl -n $ns patch deployment $pod -p "{\"spec\":{\"template\":{\"metadata\":{\"labels\":{\"configmapUpdate\":\"`date +'%s'`\"}}}}}"
                else
                        echo "UNKNOWN ERROR DURING CONFIG MAP APPLY. ERROR $RETURN"
                fi
}

#set -x

workspace=/src
oldlist=/tmp/oldlist
newlist=/tmp/newlist
donesec=()
donemap=()

# INITIAL LIST and CLONE
cd $workspace
find ! -path "./.git*" -type f -exec md5sum "{}" + > $oldlist

while true; do
	find ! -path "./.git*" -type f -exec md5sum "{}" + > $newlist

        for el in $( comm -1 -3 <(sort /tmp/oldlist) <(sort /tmp/newlist) | cut -d " " -f3 ); do

                get_data $el

                case "$el" in 
                        *namespaces*)
				kubectl create -f $el 
				;;
                        *deployments*)
                                kubectl apply -f $el 
				;;
                        *secrets*)
                                if [[ "${donesec[@]}" != *"$pod"* ]]; then
                                        deploysecrets $el
                                fi
                                donesec+=($pod)
				;;
                        *configmaps*) 
                                if [[ "${donemap[@]}" != *"$pod"* ]]; then
                                        deployconfigmap $el
                                fi
                                donemap+=($pod)
                                ;;

                        *)
                                echo "Unhandled file $el"
                                ;;
                esac
        done

        cp $newlist $oldlist
        donesec=()
        donemap=()

        sleep 10
done
