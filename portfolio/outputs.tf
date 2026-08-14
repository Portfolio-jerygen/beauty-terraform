output "raw_bucket_url" {
  description = "GCS URI for raw crawler output"
  value       = "gs://${google_storage_bucket.raw_data.name}"
}

output "bigquery_datasets" {
  description = "BigQuery layer dataset IDs"
  value       = sort([for dataset in google_bigquery_dataset.layer : dataset.dataset_id])
}

output "artifact_registry_repository" {
  description = "Artifact Registry repository resource name"
  value       = google_artifact_registry_repository.crawlers.name
}

output "service_accounts" {
  description = "Runtime service accounts"
  value = {
    crawler   = google_service_account.crawler.email
    airflow   = google_service_account.airflow.email
    dashboard = google_service_account.dashboard.email
  }
}
