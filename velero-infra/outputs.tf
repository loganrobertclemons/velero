output "service_account" {
  description = "Service Account for Velero"
  value       = module.service_account.email
}

output "bucket_name" {
  description = "Velero bucket"
  value       = module.bucket.bucket.name
}