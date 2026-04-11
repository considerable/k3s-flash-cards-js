variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "" # set via TF_VAR_project_id or -var flag
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-b"
}
