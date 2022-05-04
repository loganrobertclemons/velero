## **Bucket Creation**

Velero requires an object storage bucket in which to store backups, preferably unique to a single Kubernetes cluster. Create a GCS bucket, replacing the <YOUR_BUCKET> placeholder with the name of your bucket:

```
BUCKET=<YOUR_BUCKET>

gsutil mb gs://$BUCKET/
```

## **Service Account Creation**

If you’ll be using Velero to backup multiple clusters with multiple GCS buckets, it may be desirable to create a unique username per cluster rather than the default velero.

```
PROJECT_ID=$(gcloud config get-value project)

gcloud iam service-accounts create velero \
    --display-name "Velero Service Account"
```

Set the $SERVICE_ACCOUNT_EMAIL variable to match its email value.

```
SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Velero service account" \
  --format 'value(email)')  
```

Attach policies to give velero the necessary permissions to function:

```
ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)

gcloud iam roles create velero.server \
    --project $PROJECT_ID \
    --title "Velero Server" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"    

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
    --role projects/$PROJECT_ID/roles/velero.server

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET}
```

Create a service account key, specifying an output file (credentials-velero) in your local directory:

```
gcloud iam service-accounts keys create credentials-velero \
    --iam-account $SERVICE_ACCOUNT_EMAIL
```

## **Velero Installation**

Install velero via the cli or helm chart.

CLI:

```
velero install \
     --provider gcp \
     --plugins velero/velero-plugin-for-gcp:v1.4.0 \
     --bucket $BUCKET \
     --secret-file ./credentials-velero
```

Helm Chart:

```
helm upgrade --install velero -n velero velero -f velero/values.yaml --set-file credentials.secretContents.cloud=./velero/credentials-velero
```

Once velero is installed and pointing to a valid bucket, create the initial backup.

`velero backup create dev-namespace-backup --include-namespaces dev`

Re-install velero and point it to the backup bucket - it will detect the backup from there.

`velero restore create --from-backup dev-namespace-backup-3`
