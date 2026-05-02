variable "project_id" {}
variable "region" {}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account" "cf_sa" {
  account_id   = "cloud-fn-sa"
  display_name = "Cloud Functions Service Account"
  project      = var.project_id
}

locals {
  cf_sa_roles = [
    "roles/bigquery.admin",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/bigquery.user",
    "roles/cloudfunctions.admin",
    "roles/cloudfunctions.invoker",
    "roles/composer.worker",
    "roles/dataflow.developer",
    "roles/dataflow.worker",
    "roles/pubsub.editor",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/iam.serviceAccountUser",
    "roles/storage.objectAdmin",
    "roles/composer.admin",
    "roles/container.admin",
    "roles/compute.networkAdmin",
    "roles/iam.serviceAccountActor",
  ]

  cloudbuild_roles = [
    "roles/iam.serviceAccountUser",
    "roles/logging.logWriter",
    "roles/artifactregistry.admin",
    "roles/storage.objectViewer",
    "roles/cloudbuild.builds.builder",
  ]

  compute_default_roles = [
    "roles/storage.objectAdmin",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
    "roles/cloudbuild.builds.builder",
    "roles/dataflow.worker",
    "roles/pubsub.editor",
    "roles/bigquery.dataEditor",
  ]
}

resource "google_project_iam_member" "cf_sa_roles" {
  for_each = toset(local.cf_sa_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.cf_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset(local.cloudbuild_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_default_roles" {
  for_each = toset(local.compute_default_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "composer_service_agent_ext" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${data.google_project.current.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

output "cf_sa_email" {
  value = google_service_account.cf_sa.email
}