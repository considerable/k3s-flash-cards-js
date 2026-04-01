variable "project_id" {
  description = "GCP project ID"
  type        = string
  default     = "YOUR_GCP_PROJECT"
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
