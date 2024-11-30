# Vagrant K8s

Lorem ipsum

## Known Issues

Rocky 9.5 came out the week of Nov. 18, 2024. According to this [Rocky forum thread](https://forums.rockylinux.org/t/issue-downloading-rocky-linux-9-vagrant-box/16627/2) the Rocky Release Engineers have not yet updated the Vagrant page. So the following manual step is required to keep using `4` until `5` is officially listed on the site as a box version.

```console
$ wget https://dl.rockylinux.org/vault/rocky/9.4/images/x86_64/Rocky-9-Vagrant-Vbox-9.4-20240509.0.x86_64.box -O Rocky-9-Vagrant-Vbox-9.4-20240509.0.x86_64.box
$ vagrant box add --architecture amd64 --provider virtualbox --name rockylinux/9 Rocky-9-Vagrant-Vbox-9.4-20240509.0.x86_64.box
```

Additionally the version constraint in the `Vagrantfile` must be commented out for now since constraints are only supported by boxes from Vagrant Cloud or a custom box host, not a direct download such as this.

## Additional Resources

* [kubeadm Configuration (v1beta4)](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/)
* [CRI-O Packaging](https://github.com/cri-o/packaging/blob/main/README.md#distributions-using-rpm-packages)
* [Cilium Quick Installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)
* [Auto-scale Metrics Server Installation](https://github.com/kubernetes-sigs/metrics-server?tab=readme-ov-file#installation)
* [Vagrant Libvirt Provider](https://github.com/vagrant-libvirt/vagrant-libvirt)
* [Vagrantfile and Scripts to Automate Kubernetes Setup using Kubeadm [Practice Environment for CKA/CKAD and CKS Exams]](https://github.com/techiescamp/vagrant-kubeadm-kubernetes/tree/main)
* [Kubespray Vagrantfile](https://github.com/kubernetes-sigs/kubespray/blob/master/Vagrantfile)
* [Helm Docs](https://helm.sh/docs/)
* [Kubernetes Cluster API](https://cluster-api.sigs.k8s.io/introduction)
* [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
