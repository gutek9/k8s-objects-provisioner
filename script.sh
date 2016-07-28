#!/bin/bash

echo "This is a idle script (infinite loop) to keep container running."
echo "running kubectl.."

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

touch /tmp/filelist.txt || exit

while [ 1 ]
do
  sleep 15 &
  wait $!
  find /src/$NAMESPACE   -type f -not -path "*.git*"  -exec md5sum {} +   > /tmp/filelist.new.txt
   comm -1 -3 <(sort /tmp/filelist.txt) <(sort /tmp/filelist.new.txt) > /tmp/filelist.process.txt

  while read line
  do
      # echo -e "$line \n"
      SUBSTRING=$(echo $line|  cut -d' '  -f2)
      echo  "File $SUBSTRING has changed, processing at $date"
      kubectl apply -f $SUBSTRING
  done < /tmp/filelist.process.txt


  mv /tmp/filelist.new.txt  /tmp/filelist.txt

done



# 1) lista plikow z hashami
# 2) nowa lista porownanie listy
#
# lista
# lista.new
#
# porownanie -> lista.process
# mv lista.new -> lista
#
# 3) process na plikach ktore zmienily hashe
# 4) process parallel
