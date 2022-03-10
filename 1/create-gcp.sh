#!/bin/bash
USER_NAME="user"
KEY_NAME="id_rsa"
CONFIG_NAME="key_config"
INSTANCE_NAME="cc-script-instance"
ZONE_NAME="europe-west3-a"

# Create SSH key
ssh-keygen -b 2048 -t rsa -f $KEY_NAME -q -N "" -C $USER_NAME
# Prepare GCP metadata format
echo -n $USER_NAME > $CONFIG_NAME
echo -n ":" >> $CONFIG_NAME
cat $KEY_NAME.pub >> $CONFIG_NAME

# Create inbound SSH+ICMP rule
# applying to network tag cloud-computing
gcloud compute firewall-rules create cc-script-ssh-icmp \
  --allow=tcp:22,icmp \
  --target-tags=cloud-computing

# Upload SSH key
gcloud compute project-info add-metadata \
  --metadata-from-file=ssh-keys=$CONFIG_NAME

# Create new instance. 30GB to match AWS
gcloud compute instances create $INSTANCE_NAME \
  --zone $ZONE_NAME \
  --image-family "ubuntu-1804-lts" \
  --image-project "ubuntu-os-cloud" \
  --tags "cloud-computing" \
  --machine-type "e2-standard-2" \
  --boot-disk-size "30GB"

# Extract IP address of the running machine
IP=$(gcloud compute instances describe cc-script-instance \
  --zone=$ZONE_NAME \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
  )

echo $IP

# Login
# ssh -i $KEY_NAME $USER_NAME@$IP
