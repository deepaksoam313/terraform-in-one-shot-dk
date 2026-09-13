resource "google_compute_instance" "test_vm_deepak" {
  machine_type = "e2-standard-2"
  name         = "test-vm"

  tags = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    subnetwork = "default"

    access_config {
      # Ephemeral external IP
    }
  }



  metadata_startup_script = <<-EOT
#!/bin/bash

    apt-get update
    apt-get install -y nginx

    systemctl enable nginx
    systemctl start nginx

    echo "<h1>Hello from test-vm</h1>" > /var/www/html/index.html
EOT

  allow_stopping_for_update = true


}