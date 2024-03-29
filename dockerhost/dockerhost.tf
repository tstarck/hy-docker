# VM host for running Docker

provider "libvirt" {
  uri = "qemu:///system"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloudinit.cfg")}"
}

resource "libvirt_cloudinit_disk" "init" {
  name = "init.iso"
  user_data = "${data.template_file.user_data.rendered}"
}

resource "libvirt_volume" "docker_vol" {
  name = "debian10.qcow2"
  format = "qcow2"
  pool = "default"
  # Pre-resize the cloud image before use
  source = "http://127.0.0.1:8000/debian-buster-amd64.qcow2"
}

resource "libvirt_domain" "dockerhost" {
  vcpu = 2
  memory = "2048"
  name = "dockerhost"

  cloudinit = "${libvirt_cloudinit_disk.init.id}"

  disk {
    volume_id = "${libvirt_volume.docker_vol.id}"
  }

  network_interface {
    network_name = "default"
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type = "pty"
    target_port = "1"
    target_type = "virtio"
  }
}
