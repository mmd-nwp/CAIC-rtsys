#!/bin/sh

post=/home/caic/caic/rtsys/snowpack/runs/post

# Check hash for any changes.

hashfile=$post/hash/hash.txt

chkhash=`curl -s -X GET "https://avid-api.avalanche.state.co.us/public/en/products/all/hash" -H "accept: application/json" -H "x-api-key: 28bc694e-7151-4c63-9c31-ae41f78e7aa1" | jq '.hash'`

if [ -f $hashfile ]; then
  curhash=`cat $hashfile`
else
  curhash="empty"
fi

if [ $curhash == $chkhash ]; then
  exit 0
fi

echo $chkhash > $hashfile

date=`date -d "+6 hours" -u +%y%j`

# Fill db with danger and problems.

/usr/bin/python3 $post/bin/danger-ingest.py

# Create danger json file for model dashboard.

/usr/bin/python3 $post/bin/danger-json.py << endin
$date
endin

# Create danger by elevation band .

date=`date -d "+6 hours" -u +%Y-%m-%d`
/usr/bin/python3.12 $post/bin/danger-elev.py --time $date

# Sync profiles to AWS.

/ssd/snowpack/bin/sp-danger-sync.sh

exit 0
