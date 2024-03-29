How-to: Create a Hadoop/Spark Cluster on CherryServer using only Terraform
---

## Description

In this tutorial, we will be creating 3 servers on the CherryServers Provider 
in order to setup a 3 node hadoop/spark cluster, with 1 master server and 2 slaves.  

We will be using Terraform for both configuring the CherryServers account and in order to
provision the servers within CherryServers. We will also be configuring the servers themselves.
Some experience with Ansible will make this easier to follow, but is not completely necessary.

## Requirements

- Make sure you have Terraform installed locally. 
Instructions can be found [here](https://learn.hashicorp.com/terraform/getting-started/install.html)

- `Terraform init` should automatically download the cherryservers terraform module for you, but if for some reason this isn't available, you can install it yourself by following these instructions [https://github.com/cherryservers/terraform-provider-cherryservers](https://github.com/cherryservers/terraform-provider-cherryservers)

## Directions

- Create an API Key for your CherryServers account at [https://portal.cherryservers.com/#/settings/api-keys](https://portal.cherryservers.com/#/settings/api-keys)

    Save your API Key somewhere safe and optionally add it to your `~/.profile` file like so and restart your terminal:

    ```
    export CHERRY_AUTH_TOKEN="2b00042f7481c7b056c4b410d28f33cf"
    ```


- Next, you will need an SSH key with which to access your servers and for terraform to use to provision your servers automatically.

    ```
    ssh-keygen -f ~/.ssh/cherry
    ```

    This will create `~/.ssh/cherry` and `~/.ssh/cherry.pub`

    This is the SSH key you will use in order to SSH into your Cherry Server and use with Ansible.  
    
-   (Optional) You can configure your ~/.ssh/config to use this new key with the IP addresses for your servers that we will create further below.

-   (Optional) While we're add it.  We're going to create a second SSH key that will be used by Hadoop and Spark.  
    Hadoop and Spark master servers SSH into the slaves within their cluster in order to manage them.  
    
    Our Terraform provisioners will upload this second SSH key to the new servers we create and allow the `hadoop` and `spark` users to SSH using this key. 
    
    When generating this second key, have it save to the relative directory here.

    ```
    cd terraform/
    ssh-keygen -f test-key
    ```

    This will create `terraform/test-key` and `terraform/test-key.pub`
    
    
- Let's run `terraform init` in the `terraform/` subdirectory to install the required terraform modules

- In `variables.tf` we configure certain parameters that should be self explanatory:

    ```
    # User Variables
    variable "region" {
      default = "EU-East-1"
    }
    variable "image" {
      default = "Ubuntu 18.04 64bit"
    }
    variable "project_name" {
      default = "Terraform Hadoop Project"
    }
    variable "team_id" {
      default = "35587"
    }
    variable "plan_id" {
      default = "113"
    }
    variable "private_key" {
      default = "~/.ssh/cherry"
    }
    variable "hadoop_private_key" {
      default = "~/.ssh/cherry"
    }
    ```
    
    You can modify your `project_name`,`team_id`, `image`, `plan_id`(server type) and set the paths to your private ssh keys in this file. In this example, we are using the same SSH key for `private_key` and `hadoop_private_key`, but it is recommended to use a separate key for hadoop as the `private_key` has root privileges.

- Once this is set, you can simply run (and type yes and press enter when it asks you to confirm)
    ```bash
    terraform apply
    ```
    
    This will create your Project, reserve 3 public static IP addresses, and create 1 master node and 2 data nodes with hadoop and spark installed on them. This process may take up to 20 minutes to complete
    
    At the end of the process, you should see some output, which will tell you the IP of the master node, or you can run `terraform output master_ip` to find the master IP for your cluster:
    
    After you are done with this cluster, simply run `terraform destroy` and all the resources (project, IPs, servers, etc) will be automatically deleted from Cherry Servers.
    
    
- The Cluster should now be ready and you will be able to access the admin panels via:

    Hadoop UI: [http://master_ip:50700]()

    Spark UI: [http://master_ip:8080]()
