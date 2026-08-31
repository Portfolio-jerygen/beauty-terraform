variable "project_id" {
  description = "GCP project ID used for the portfolio pipeline"
  type        = string

  validation {
    condition     = length(trimspace(var.project_id)) > 0
    error_message = "project_id must not be empty."
  }
}

variable "region" {
  description = "GCP region for regional resources and BigQuery datasets"
  type        = string
  default     = "asia-northeast3"
}

variable "environment" {
  description = "Environment label applied to managed resources"
  type        = string
  default     = "portfolio"
}

variable "raw_bucket_name" {
  description = "Globally unique GCS bucket name; defaults to <project_id>-beauty-raw"
  type        = string
  default     = null
  nullable    = true
}

variable "credentials_file" {
  description = "Optional service-account JSON path. Prefer Application Default Credentials."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}
