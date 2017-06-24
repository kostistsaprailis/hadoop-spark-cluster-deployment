# Automatic Deployment of a Hadoop-Spark Cluster using Terraform
---

This is a project I created for the `Big Data Systems & Techniques` course of my MSc in Data Science.
It's a very basic implementation of an orchestration systems that provisions and configures a 3-node cluster (the number of data-nodes can be easily extended) with Apache Hadoop and Apache Spark.

## Project's Task

The task of this project is to use the [Terraform](https://terraform.io) IAC (Infrastructure as Code) tool to automatically provision Amazon VMs and install Hadoop on the cluster.
The resources used are:
- Linux image: `Ubuntu 16.04`
- Java: `jdk1.8.0_131`
- Apache Hadoop: `hadoop-2.7.2`
- Apache Spark: `spark-2.1.1`

## What is Infrastructure As Code and what is Terraform?

Infrastructure as code is a new DevOps philosophy where the application infrastructure is no longer created by hand but programmatically. The benefits are numerous
including but not limited to:
- Speed of deployment
- Version Control of Infrastructure
- Engineer agnostic infrastructure (no single point of failure/no single person to bug)
- Better lifetime management (automatic scale up/down, healing)
- Cross-provider deployment with minimal changes

Terraform is a tool that helps in this direction. It is an open source tool developed by [Hashicorp](https://www.hashicorp.com/).

This tool allows you to write the final state that you wish your infrastructure to have and terraform applies those changes for you.

You can provision VMs, create subnets, assign security groups and pretty much perform any action that any cloud provider allows.

Terraform support a wide range of [providers](https://www.terraform.io/docs/providers/index.html) including the big 3 ones AWS, GCP, Microsoft Azure.

## Installing Terraform

Terraform is written in Go and is provided as a binary for the major OSs but can also be compiled from [source code](https://github.com/hashicorp/terraform).

The binary can be downloaded from the Terraform [site](https://www.terraform.io/downloads.html) and does not require any installation. We just need to set it to the path variable (for Linux/macOS instructionscan be found [here](https://stackoverflow.com/questions/14637979/how-to-permanently-set-path-on-linux) and for Windows [here](https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows)) so that it is accessible from our system in any path.

After we have this has finished we can confirm that it is ready to be used by running the terraform command and we should get something like the following:

```
$ terraform
Usage: terraform [--version] [--help] <command> [args]

The available commands for execution are listed below.
The most common, useful commands are shown first, followed by
less common or more advanced commands. If you're just getting
started with Terraform, stick with the common commands. For the
other commands, please read the help and docs before usage.

Common commands:
    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
    destroy            Destroy Terraform-managed infrastructure
    env                Environment management
    fmt                Rewrites config files to canonical format
    get                Download and install modules for the configuration
    graph              Create a visual graph of Terraform resources
    import             Import existing infrastructure into Terraform
    init               Initialize a new or existing Terraform configuration
    output             Read an output from a state file
    plan               Generate and show an execution plan
    push               Upload this Terraform module to Atlas to run
    refresh            Update local state file against real resources
    show               Inspect Terraform state or plan
    taint              Manually mark a resource for recreation
    untaint            Manually unmark a resource as tainted
    validate           Validates the Terraform files
    version            Prints the Terraform version

All other commands:
    debug              Debug output management (experimental)
    force-unlock       Manually unlock the terraform state
    state              Advanced state management
```

Now we can move on the using the tool.

## Setting up the AWS account

This is a step that is not specific to this project but rather it's something that needs to be configured whenever a new AWS account is set up.
When we create a new account with Amazon, the default account we are given has root access to any action. Similarly with the linux root user we do not want to be using this account for the day-to-day actions, so we need to create a new user.

We navigate to the [Identity and Access Management (IAM)](https://console.aws.amazon.com/iam/home#) page, click on `Users`, then the `Add user` button. We provide the User name, and click the Programmatic access checkbox so that an access key ID and a secret access key will be generated.

Clicking next we are asked to provide a Security Group that this User will belong to. Security Groups are the main way to provide permission and restrict access to specific actions required. For this purpose of this project we will give the `AdministratorAccess` permission to this user, however when used in a professional setting it is advised to only allow permissions that a user needs (like AmazonEC2FullAccess if a user will only be creating EC2 instances).

Finishing the review step Amazon will provide the Access key ID and Secret access key. We will provide these to terraform to grant it access to create the resources for us. We need to keep these as they are only provided once and cannot be retrieved (however we can always create a new pair).

The secure way to store these credentials as recommended by [Amazon](https://aws.amazon.com/blogs/security/a-new-and-standardized-way-to-manage-credentials-in-the-aws-sdks/) is keeping them in a hidden folder under a file called `credentials`. This file can be accessed by terraform to retrieve them.

```
$ cd
$ mkdir .aws
$ cd .aws
~/.aws$ vim credentials
```

We add the following to the credentials file after replacing `ACCESS_KEY` and `SECRET_KEY` and then save it:

```
[default]
aws_access_key_id = ACCESS_KEY
aws_secret_access_key = SECRET_KEY
```

We also restrict access to this file only to the current user:

```
~/.aws$ chmod 600 credentials 
```

## Setting up a key pair

The next step is to create a key pair so that terraform can access the newly created VMS. Notice that this is different than the above credentials. The Amazon credentials are for accessing and allowing the AWS service to create the resources required, while this key pair will be used for accessing the new instances. 

Log into the [AWS console](https://eu-west-1.console.aws.amazon.com/ec2/v2/home?region=eu-west-1#KeyPairs:sort=keyName) and select `Create Key Pair`. Add a name and click `Create`. AWS will create a .pem file and download it locally. 

Move this file to the `.aws` directory.
```
~/Downloads$ mv ssh-key.pem ../.aws/
```

The restrict the permissions:
```
$ chmod 400 ssh-key.pem
```

Now we ready to use this key pair either via a direct ssh to our instances, or for terraform to use this to connect to the instances and run some scripts.

## Provisioning VMs & Configuring Them

The following terraform script is responsible for the creation of the VM instances, copying the relevant keys to give us access to them as well as run the startup script that configures the nodes.

We run this with `terraform plan` and terraform informs us about the changes it's going to make:

```
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_instance.Datanode.0
    ami:                          "ami-a8d2d7ce"
    associate_public_ip_address:  "<computed>"
    availability_zone:            "<computed>"
    ebs_block_device.#:           "<computed>"
    ephemeral_block_device.#:     "<computed>"
    instance_state:               "<computed>"
    instance_type:                "t2.micro"
    ipv6_address_count:           "<computed>"
    ipv6_addresses.#:             "<computed>"
    key_name:                     "ssh-key"
    network_interface.#:          "<computed>"
    network_interface_id:         "<computed>"
    placement_group:              "<computed>"
    primary_network_interface_id: "<computed>"
    private_dns:                  "<computed>"
    private_ip:                   "172.31.32.102"
    public_dns:                   "<computed>"
    public_ip:                    "<computed>"
    root_block_device.#:          "<computed>"
    security_groups.#:            "<computed>"
    source_dest_check:            "true"
    subnet_id:                    "<computed>"
    tags.%:                       "1"
    tags.Name:                    "s02"
    tenancy:                      "<computed>"
    volume_tags.%:                "<computed>"
    vpc_security_group_ids.#:     "<computed>"

+ aws_instance.Datanode.1
    ami:                          "ami-a8d2d7ce"
    associate_public_ip_address:  "<computed>"
    availability_zone:            "<computed>"
    ebs_block_device.#:           "<computed>"
    ephemeral_block_device.#:     "<computed>"
    instance_state:               "<computed>"
    instance_type:                "t2.micro"
    ipv6_address_count:           "<computed>"
    ipv6_addresses.#:             "<computed>"
    key_name:                     "ssh-key"
    network_interface.#:          "<computed>"
    network_interface_id:         "<computed>"
    placement_group:              "<computed>"
    primary_network_interface_id: "<computed>"
    private_dns:                  "<computed>"
    private_ip:                   "172.31.32.103"
    public_dns:                   "<computed>"
    public_ip:                    "<computed>"
    root_block_device.#:          "<computed>"
    security_groups.#:            "<computed>"
    source_dest_check:            "true"
    subnet_id:                    "<computed>"
    tags.%:                       "1"
    tags.Name:                    "s03"
    tenancy:                      "<computed>"
    volume_tags.%:                "<computed>"
    vpc_security_group_ids.#:     "<computed>"

+ aws_instance.Namenode
    ami:                          "ami-a8d2d7ce"
    associate_public_ip_address:  "<computed>"
    availability_zone:            "<computed>"
    ebs_block_device.#:           "<computed>"
    ephemeral_block_device.#:     "<computed>"
    instance_state:               "<computed>"
    instance_type:                "t2.micro"
    ipv6_address_count:           "<computed>"
    ipv6_addresses.#:             "<computed>"
    key_name:                     "ssh-key"
    network_interface.#:          "<computed>"
    network_interface_id:         "<computed>"
    placement_group:              "<computed>"
    primary_network_interface_id: "<computed>"
    private_dns:                  "<computed>"
    private_ip:                   "172.31.32.101"
    public_dns:                   "<computed>"
    public_ip:                    "<computed>"
    root_block_device.#:          "<computed>"
    security_groups.#:            "<computed>"
    source_dest_check:            "true"
    subnet_id:                    "<computed>"
    tags.%:                       "1"
    tags.Name:                    "s01"
    tenancy:                      "<computed>"
    volume_tags.%:                "<computed>"
    vpc_security_group_ids.#:     "<computed>"

+ aws_security_group.instance
    description:                           "Managed by Terraform"
    egress.#:                              "1"
    egress.482069346.cidr_blocks.#:        "1"
    egress.482069346.cidr_blocks.0:        "0.0.0.0/0"
    egress.482069346.from_port:            "0"
    egress.482069346.ipv6_cidr_blocks.#:   "0"
    egress.482069346.prefix_list_ids.#:    "0"
    egress.482069346.protocol:             "-1"
    egress.482069346.security_groups.#:    "0"
    egress.482069346.self:                 "false"
    egress.482069346.to_port:              "0"
    ingress.#:                             "4"
    ingress.2214680975.cidr_blocks.#:      "1"
    ingress.2214680975.cidr_blocks.0:      "0.0.0.0/0"
    ingress.2214680975.from_port:          "80"
    ingress.2214680975.ipv6_cidr_blocks.#: "0"
    ingress.2214680975.protocol:           "tcp"
    ingress.2214680975.security_groups.#:  "0"
    ingress.2214680975.self:               "false"
    ingress.2214680975.to_port:            "80"
    ingress.2319052179.cidr_blocks.#:      "1"
    ingress.2319052179.cidr_blocks.0:      "0.0.0.0/0"
    ingress.2319052179.from_port:          "9000"
    ingress.2319052179.ipv6_cidr_blocks.#: "0"
    ingress.2319052179.protocol:           "tcp"
    ingress.2319052179.security_groups.#:  "0"
    ingress.2319052179.self:               "false"
    ingress.2319052179.to_port:            "9000"
    ingress.2541437006.cidr_blocks.#:      "1"
    ingress.2541437006.cidr_blocks.0:      "0.0.0.0/0"
    ingress.2541437006.from_port:          "22"
    ingress.2541437006.ipv6_cidr_blocks.#: "0"
    ingress.2541437006.protocol:           "tcp"
    ingress.2541437006.security_groups.#:  "0"
    ingress.2541437006.self:               "false"
    ingress.2541437006.to_port:            "22"
    ingress.3302755614.cidr_blocks.#:      "1"
    ingress.3302755614.cidr_blocks.0:      "0.0.0.0/0"
    ingress.3302755614.from_port:          "50010"
    ingress.3302755614.ipv6_cidr_blocks.#: "0"
    ingress.3302755614.protocol:           "tcp"
    ingress.3302755614.security_groups.#:  "0"
    ingress.3302755614.self:               "false"
    ingress.3302755614.to_port:            "50010"
    name:                                  "Namenode-instance"
    owner_id:                              "<computed>"
    vpc_id:                                "<computed>"


Plan: 4 to add, 0 to change, 0 to destroy.
```

Then we run `terraform apply` to start the creation of our resources. Once we are done we can see that terraform has output the dns name of the master node so that we can login to it and start out services.

In order to remove all resources we run `terraform destroy`.

## Using Configuration Tools
While using the above bash script is OK for a small project, we want to use a more advanced configuration tool is we are going to use terraform in production.
There are many choices here, with the main being `Chef` that terraform supports natively, however all we can use the rest of the major tools like Ansible, Puppet etc if they are installed in our local terraform machine.

Furthermore Terraform suggests creating custom images using the [Packer](https://www.packer.io) tool. Customer images are built using the base linux (or any other image) after we have added the software required. This is then packaged into a single image which is loaded into the VM ready to be used. This saves both time, as well as bandwidth when creating the infrastructure.

## Future improvements
As mentioned above the goal is to make this more customizable regarding the number of nodes that can be created, the versions of Java, Hadoop, Spark used, as well as the instance type of the nodes.

## Resources:

- [Terraform](https://www.terraform.io/intro/index.html)
- [AWS](https://www.terraform.io/docs/providers/aws/index.html)
- [Google Cloud](https://www.terraform.io/docs/providers/google/index.html)
- [Introduction to Packer](https://www.packer.io/intro/getting-started/install.html)
- [Using Chef](https://www.terraform.io/docs/provisioners/chef.html)
- [Using Ansible](https://www.trainingdevops.com/training-material/ansible-workshop/using-ansible-with-terrafoam)