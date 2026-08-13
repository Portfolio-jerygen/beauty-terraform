locals {
  raw_bucket_name = coalesce(var.raw_bucket_name, "${var.project_id}-beauty-raw")

  common_labels = {
    project     = "beauty-commerce"
    environment = var.environment
    managed_by  = "terraform"
  }

  dataset_ids = toset([
    "bronze",
    "silver",
    "gold",
    "metadata",
  ])
}

resource "google_storage_bucket" "raw_data" {
  name                        = local.raw_bucket_name
  project                     = var.project_id
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels                      = local.common_labels

  versioning {
    enabled = true
  }

  depends_on = [google_project_service.required]
}

resource "google_bigquery_dataset" "layer" {
  for_each = local.dataset_ids

  project                    = var.project_id
  dataset_id                 = each.value
  friendly_name              = "Beauty ${title(each.value)}"
  description                = "${title(each.value)} layer for the beauty commerce portfolio pipeline"
  location                   = var.region
  delete_contents_on_destroy = false
  labels                     = local.common_labels

  depends_on = [google_project_service.required]
}

resource "google_artifact_registry_repository" "crawlers" {
  project       = var.project_id
  location      = var.region
  repository_id = "beauty-crawlers"
  description   = "Container images for beauty commerce crawler jobs"
  format        = "DOCKER"
  labels        = local.common_labels

  depends_on = [google_project_service.required]
}

resource "google_service_account" "crawler" {
  project      = var.project_id
  account_id   = "beauty-crawler"
  display_name = "Beauty crawler Cloud Run jobs"
}

resource "google_service_account" "airflow" {
  project      = var.project_id
  account_id   = "beauty-airflow"
  display_name = "Beauty Airflow orchestration"
}

resource "google_service_account" "dashboard" {
  project      = var.project_id
  account_id   = "beauty-dashboard"
  display_name = "Beauty dashboard read-only queries"
}

# The crawler only creates raw objects. It cannot read or delete existing data.
resource "google_storage_bucket_iam_member" "crawler_object_creator" {
  bucket = google_storage_bucket.raw_data.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.crawler.email}"
}

# Airflow reads raw objects and submits BigQuery load/query jobs.
resource "google_storage_bucket_iam_member" "airflow_object_viewer" {
  bucket = google_storage_bucket.raw_data.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.airflow.email}"
}

resource "google_project_iam_member" "airflow_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

resource "google_project_iam_member" "airflow_cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

resource "google_bigquery_dataset_iam_member" "airflow_data_editor" {
  for_each = google_bigquery_dataset.layer

  project    = var.project_id
  dataset_id = each.value.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.airflow.email}"
}

# The public dashboard can run queries and read only the curated Gold layer.
resource "google_project_iam_member" "dashboard_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.dashboard.email}"
}

resource "google_bigquery_dataset_iam_member" "dashboard_gold_viewer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.layer["gold"].dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.dashboard.email}"
}
