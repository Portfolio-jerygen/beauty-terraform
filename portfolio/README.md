# Beauty Commerce Portfolio Infrastructure

This directory is an independent Terraform root module for the small,
reproducible version of the Beauty Commerce data pipeline. The Terraform files
in the repository root are the original project configuration and remain
unchanged.

## Managed resources

- GCS raw-data bucket with public access prevention and object versioning
- BigQuery `bronze`, `silver`, `gold`, and `metadata` datasets
- Artifact Registry Docker repository for crawler images
- Separate crawler, Airflow, and dashboard service accounts
- Additive, least-privilege IAM grants for each runtime
- Required Google Cloud APIs

This initial portfolio scope intentionally does **not** create an Airflow VM,
Dataproc cluster, Cloud Run job, or service-account key. Those resources depend
on validated application images and should be added after the local pipeline
works.

## Prerequisites

1. Create a GCP project and attach billing.
2. Install Terraform and the Google Cloud CLI.
3. Authenticate with Application Default Credentials:

   ```bash
   gcloud auth application-default login
   ```

4. Copy the example variables file and set your project ID:

   ```bash
   cd portfolio
   cp terraform.tfvars.example terraform.tfvars
   ```

## Usage

Run Terraform only from this directory:

```bash
cd portfolio
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Always review `terraform plan` before applying. The bucket and BigQuery
datasets are configured to resist accidental deletion of stored data.

## Authentication

Application Default Credentials are preferred. `credentials_file` remains
available only for constrained environments that cannot use ADC. Never commit
JSON credentials, `.tfvars`, state files, or local plan files.

## Follow-up infrastructure

After the crawler image and local Airflow DAG are verified:

1. Add a Cloud Run Job referencing the published crawler image.
2. Grant the Cloud Run runtime the crawler service account.
3. Configure local Airflow to use the Airflow service account.
4. Deploy Streamlit using the read-only dashboard identity.
5. Add an Airflow VM only if a continuously hosted scheduler is needed.
