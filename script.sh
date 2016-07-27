#!/bin/bash

echo "This is a idle script (infinite loop) to keep container running."
echo "running kubectl.."

cleanup ()
{
  kill -s SIGTERM $!
  exit 0
}

trap cleanup SIGINT SIGTERM

while [ 1 ]
do
  sleep 15 &
  wait $!
  kubectl apply -f /src/$NAMESPACE --recursive
done
