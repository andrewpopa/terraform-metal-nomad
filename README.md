# Nomad on Equinix Metal

## Table of Contents
- [Pre-requirement](#pre-requirements)
- [Usage](#usage)

## Pre-requirements

↥ [back to top](#table-of-contents)

- [Terraform](https://www.terraform.io/downloads.html)
- [Equinix Metal](https://console.equinix.com/)

## Usage

↥ [back to top](#table-of-contents)

Make sure you are [authenticated](https://registry.terraform.io/providers/equinix/equinix/latest/docs) to Equinix Metal

```shell
env | egrep -i "metal|equinix"
METAL_AUTH_TOKEN=XXX
EQUINIX_API_CLIENTID=XXX
EQUINIX_API_CLIENTSECRET=XXX
```

clone the repository

```shell
git clone git@github.com:andrewpopa/terraform-metal-nomad.git
cd terraform-metal-nomad
```

make sure you edit `terraform.tfvars` with correct values

deploy the infrastructure

```
terraform init
terraform apply
```

This will deploy Nomad cluster according on [Reference Architecture](https://learn.hashicorp.com/tutorials/nomad/production-reference-architecture-vm-with-consul)


delete the environment when needed

```
terraform destroy
```