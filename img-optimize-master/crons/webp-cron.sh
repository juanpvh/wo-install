#!/bin/bash

## cronjob to convert PNG/JPG images to WebP
## images path are listed in sites.csv
## written by VirtuBox (https://virtubox.net)

sites=$(ls -1L /var/www -I22222 -Ihtml)

for site in ${sites[@]}; do
# convert png to webp
{
find "$site" -ctime 0 -type f -iname "*.png" -print0 | xargs -0 -I {}  \
bash -c '[ ! -f "{}.webp" ] && { cwebp -z 9 -mt {} -o {}.webp; }' >> /var/log/webp-cron.log 2>&1
# convert jpg  to webp
find "$site" -ctime 0 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) -print0 | xargs -0 -I {} \
bash -c '[ ! -f "{}.webp" ] && { cwebp -q 82 -mt {} -o {}.webp; }'
} >> /var/log/webp-cron.log 2>&1
done

