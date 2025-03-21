# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.3.0"

# Load Ruby Gems:
require 'yaml'

# Load settings & servers from file:
settings = YAML.load_file('./settings.yml')
servers = settings['servers']
controlplanes = servers.select{|server| server['roles'].include? 'control-plane'}
workers = servers.select{|server| server['roles'].include? 'worker'}

# Environmental Variables:
ENV['CILIUM_VERSION'] = '1.16.3'
ENV['CRIO_VERSION'] = '1.31'
ENV['HELM_VERSION'] = '3.16.3'
ENV['KUBE_API_ENDPOINT'] = controlplanes[0]['ipv4']  # In HA, really should be TCP load balancer.
ENV['KUBE_CERTIFICATE_KEY'] = 'e6a2eb8581237ab72a4f494f30285ec12a9694d750b9785706a83bfcbbbd2204'
ENV['KUBE_CLUSTER_DNS'] = '172.17.0.10'
ENV['KUBE_CLUSTER_DNS_DOMAIN'] = 'helena.cluster'
ENV['KUBE_CLUSTER_NAME'] = 'helena'
ENV['KUBE_CLUSTER_POD_CIDR'] = '172.16.1.0/16'
ENV['KUBE_CLUSTER_SVC_CIDR'] = '172.17.1.0/18'
ENV['KUBE_VERSION'] = '1.31'
ENV['VAGRANT_BOX'] = 'rockylinux/9'
# ENV['VAGRANT_BOX_VERSION'] = '5.0.0'
ENV['VAGRANT_BOX_VERSION'] = '0'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Avoid updating the guest additions if the user has the plugin installed:
#   if Vagrant.has_plugin?("vagrant-vbguest")
#     config.vbguest.auto_update = false
#   end

  # Display a note when running the machine.
  config.vm.post_up_message = "Remember, switch to root shell before running K8s commands!"

  # Share an additional folder to the guest VM.
  config.vm.synced_folder "./work", "/vagrant_work", SharedFoldersEnableSymlinksCreate: false

  ##############################################################
  # Create the control-plane nodes.                            #
  ##############################################################
  controlplanes.each_with_index do |server, index|

    config.vm.define server['name'] do |node|

      # VM details
      node.vm.box = ENV['VAGRANT_BOX']
      node.vm.box_version = ENV['VAGRANT_BOX_VERSION']
      node.vm.hostname = server['name']
      node.vm.network "private_network",
        ip: server['ipv4']
        # libvirt__netmask: '255.255.255.0',
        # libvirt__network_name: 'default',
        # libvirt__forward_mode: 'none' 

      # VirtualBox provider
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = server['cpus']
        vb.default_nic_type = "virtio"
        vb.gui = false
        vb.memory = server['memory']
        vb.name = server['name']
        vb.customize ["modifyvm", :id, "--groups", ("/" + ENV['KUBE_CLUSTER_NAME'])]
      end

      # Libvirt provider
      node.vm.provider "libvirt" do |lv|
        # Use QEMU session instead of system connection
        lv.qemu_use_session = true
        # URI of QEMU session connection
        lv.uri = 'qemu:///session'
        # URI of QEMU system connection, use to obtain IP address for management
        lv.system_uri = 'qemu:///system'
        # Path to store Libvirt images for the virtual machine
        lv.storage_pool_path = '~/.local/share/libvirt/images'
        # Management network device, default is below
        lv.management_network_device = 'virbr0'

        lv.memory = server['memory']
        lv.cpus = server['cpus']
        lv.default_prefix = ENV['KUBE_CLUSTER_NAME']
      end

      # # Libvirt provider
      # node.vm.provider "libvirt" do |lv|
      #   lv.qemu_use_session = true
      #   lv.nested = false
      #   lv.cpu_mode = "host-model"
      #   lv.memory = server['memory']
      #   lv.cpus = server['cpus']
      #   lv.default_prefix = ENV['KUBE_CLUSTER_NAME']
      # end

      # Base node installation
      node.vm.provision "shell" do |script|
        script.env = {
          CRIO_VERSION: ENV['CRIO_VERSION'],
          KUBE_VERSION: ENV['KUBE_VERSION']
        }
        script.path = "./scripts/node.sh"
      end

      if index < 1
        # The first control-plane node housekeeping during `vagrant destroy`.
        # node.trigger.before :destroy do |trigger|
        #   trigger.warn = "Performing housekeeping before starting destroy..."
        #   trigger.run_remote = {
        #     path: "./scripts/housekeeping.sh"
        #   }
        # end

        # The first control-plane node installation.
        node.vm.provision "shell" do |script|
          script.env = {
            CILIUM_VERSION: ENV['CILIUM_VERSION'],
            IPV4_ADDR: server['ipv4'],
            HELM_VERSION: ENV['HELM_VERSION'],
            KUBE_API_ENDPOINT: ENV['KUBE_API_ENDPOINT'],
            KUBE_CERTIFICATE_KEY: ENV['KUBE_CERTIFICATE_KEY'],
            KUBE_CLUSTER_DNS: ENV['KUBE_CLUSTER_DNS'],
            KUBE_CLUSTER_DNS_DOMAIN: ENV['KUBE_CLUSTER_DNS_DOMAIN'],
            KUBE_CLUSTER_NAME: ENV['KUBE_CLUSTER_NAME'],
            KUBE_CLUSTER_POD_CIDR: ENV['KUBE_CLUSTER_POD_CIDR'],
            KUBE_CLUSTER_SVC_CIDR: ENV['KUBE_CLUSTER_SVC_CIDR'],
            KUBE_VERSION: ENV['KUBE_VERSION']
          }
          script.path = "./scripts/control-plane.sh"
        end
      end

      # The remaining control-plane node installation.
      if index > 0
        node.vm.provision "shell" do |script|
          script.env = {
            CILIUM_VERSION: ENV['CILIUM_VERSION'],
            HELM_VERSION: ENV['HELM_VERSION'],
            IPV4_ADDR: server['ipv4'],
            KUBE_API_ENDPOINT: ENV['KUBE_API_ENDPOINT'],
            KUBE_CERTIFICATE_KEY: ENV['KUBE_CERTIFICATE_KEY'],
            KUBE_CLUSTER_NAME: ENV['KUBE_CLUSTER_NAME'],
            KUBE_VERSION: ENV['KUBE_VERSION']
          }
          script.path = "./scripts/control-plane-join.sh"
        end
      end

    end

  end

  ##############################################################
  # Create the worker nodes.                                   #
  ##############################################################
  workers.each_with_index do |server, index|

    config.vm.define server['name'] do |node|

      # VM details
      node.vm.box = ENV['VAGRANT_BOX']
      node.vm.box_version = ENV['VAGRANT_BOX_VERSION']
      node.vm.hostname = server['name']
      node.vm.network "private_network",
        ip: server['ipv4'],
        libvirt__netmask: '255.255.255.0',
        libvirt__network_name: 'default',
        libvirt__forward_mode: 'none'

      # VirtualBox provider
      node.vm.provider "virtualbox" do |vb|
        vb.cpus = server['cpus']
        vb.default_nic_type = "virtio"
        vb.gui = false
        vb.memory = server['memory']
        vb.name = server['name']
        vb.customize ["modifyvm", :id, "--groups", ("/" + ENV['KUBE_CLUSTER_NAME'])]
      end

      # Libvirt provider
      node.vm.provider "libvirt" do |lv|
        lv.nested = false
        lv.cpu_mode = "host-model"
        lv.memory = server['memory']
        lv.cpus = server['cpus']
        lv.default_prefix = ENV['KUBE_CLUSTER_NAME']
      end

      # Base node installation
      node.vm.provision "shell" do |script|
        script.env = {
          CRIO_VERSION: ENV['CRIO_VERSION'],
          KUBE_VERSION: ENV['KUBE_VERSION']
        }
        script.path = "./scripts/node.sh"
      end

      # The worker nodes
      node.vm.provision "shell" do |script|
        script.env = {
          IPV4_ADDR: server['ipv4']
        }
        script.path = "./scripts/worker-join.sh"
      end

    end

  end

end