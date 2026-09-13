output "instance_name" {
  value = google_compute_instance.test_vm_deepak.name
}

output "instance_id"{
  value = google_compute_instance.test_vm_deepak.instance_id
}

output "instance_public_ip" {
  value = google_compute_instance.test_vm_deepak.network_interface[0].access_config[0].nat_ip
}