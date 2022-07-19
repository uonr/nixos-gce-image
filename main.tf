terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}


provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_storage_bucket" "nixos" {
  name                        = "mytah-nixos-image"
  location                    = "ASIA-NORTHEAST1"
  force_destroy               = true
  uniform_bucket_level_access = false
  storage_class               = "STANDARD"
}

resource "google_storage_bucket_object" "image" {
  name = var.image_filename
  # TODO: auto build image and fetch filename
  source = "./gce/${var.image_filename}"
  bucket = google_storage_bucket.nixos.name
}


resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.nixos.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_compute_image" "nixos" {
  # TODO: generate from filename
  name   = "nixos-image-22-11pre392657-e4d49de45a3-x86-64-linux"
  family = "nixos-22-11"
  raw_disk {
    source = google_storage_bucket_object.image.self_link
  }
}

resource "google_compute_image_iam_binding" "policy" {
  image = google_compute_image.nixos.name
  role  = "roles/compute.imageUser"
  members = [
    "allAuthenticatedUsers",
  ]
}