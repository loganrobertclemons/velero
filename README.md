Create the backup bucket and apply the proper permissions for velero to use.

`gcloud auth application-default login`

Save the credentials so that velero can use the serviceaccount to backup to the bucket.

`gcloud iam service-accounts keys create credentials-velero \            
    --iam-account $SERVICE_ACCOUNT_EMAIL`

Install velero via the cli or helm chart.

`velero install \
     --provider gcp \
     --plugins velero/velero-plugin-for-gcp:v1.4.0 \
     --bucket $BUCKET \
     --secret-file ./credentials-velero`

`helm upgrade --install velero -n velero velero -f velero/values.yaml --set-file credentials.secretContents.cloud=./velero/credentials-velero`

Once velero is installed and pointing to a valid bucket, create the initial backup.

`velero backup create dev-namespace-backup --include-namespaces dev`

You can spin up a secondary kind cluster to test restores.

`kind create cluster --name velero --image kindest/node:v1.19.1`

Re-install velero and point it to the backup bucket - it will detect the backup from there.

`velero restore create --from-backup dev-namespace-backup-3`

!!! Gotta have workload identity on the cluster enabled if you want to run the terraform as is !!!
