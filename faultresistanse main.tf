terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token = "y0_AgAAAAAm365DAATuwQAAAADiXIovzX6L_6u1Rp66rcUZBYmr421vZhA"
  cloud_id = "b1gtu18v39e0nek8s11v"
  folder_id = "b1gcclsbauu1i1arfbrt"
  zone = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {
  count = 2
  name  = "vm${count.index}"
 
  resources {
    core_fraction = 5
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8fphfpeqijnlu1phu4"
    }
  }
  
  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet1.id}"
    nat       = true
  }

  placement_policy {
      placement_group_id = "${yandex_compute_placement_group.group1.id}"
  }

metadata = {
  user-data = file ("./metadata.yaml")

}

  }
  resource "yandex_compute_placement_group" "group1" {
      name = "group1"
  }

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  zone = "ru-central1-a"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

#resource "yandex_compute_snapshot" "snapshot-1" {
#  name           = "disk-snapshot-1"
#  source_disk_id = "${yandex_compute_instance.vm[0].boot_disk[0].disk_id}"
#}

#resource "yandex_compute_snapshot" "snapshot-2" {
#  name           = "disk-snapshot-2"
#  source_disk_id = "${yandex_compute_instance.vm[1].boot_disk[0].disk_id}"
#}

resource "yandex_lb_target_group" "test-1" {
  name = "test-1"
  target {
    subnet_id = yandex_vpc_subnet.subnet1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.subnet1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }
}

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "lb-1"
  listener {
    name = "my-lb-1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.test-1.id
    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
