#!/bin/bash
echo ""
echo "Provisioner is starting.."
echo ""
echo "Provisoner for deployments will operate in ns $DEPLOYMENT_DIR  "
echo ""

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

touch /tmp/filelist.txt || exit
touch /tmp/secretlist.txt || exit



while [ 1 ]
do
  sleep 15 &
  wait $!

  ############deployments

  find /src/$DEPLOYMENT_DIR   -type f -name *.yaml -not -path "*.git*"  -exec md5sum {} +   > /tmp/filelist.new.txt
   comm -1 -3 <(sort /tmp/filelist.txt) <(sort /tmp/filelist.new.txt) > /tmp/filelist.process.txt

  while read line
  do
      # echo -e "$line \n"
      SUBSTRING=$(echo $line|  cut -d' '  -f2)
      date=$(date --iso-8601=seconds)
      echo  "File $SUBSTRING has changed, processing at $date"
      kubectl apply -f $SUBSTRING
  done < /tmp/filelist.process.txt

  mv /tmp/filelist.new.txt  /tmp/filelist.txt
  ############

done
