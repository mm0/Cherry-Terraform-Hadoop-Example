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


- The Cherry Servers module connects to Cherry Servers Public API via cherry-python package. You need to install it with pip (this might need to be done as `sudo`):

    ```bash
    pip install cherry-python
    ```
- You will need to download [this](https://github.com/cherryservers/cherry-ansible-module/tree/master/cherryservers) directory into the `ansible/library` subdirectory of this project.  
This is the Cherry Servers Ansible Module that we will use to interact with Cherry Server's API. The `ansible.cfg` file in the `ansible` directory has a `library` entry that points to the `library` subdirectory and tells ansible where to find our custom modules.


## Directions

- Create an API Key for your CherryServers account at [https://portal.cherryservers.com/#/settings/api-keys](https://portal.cherryservers.com/#/settings/api-keys)

    Save your API Key somewhere safe and optionally add it to your `~/.profile` file like so:

    ```
    export CHERRY_AUTH_TOKEN="2b00042f7481c7b056c4b410d28f33cf"
    ```


- Next, you will need an SSH key with which to access your servers and for ansible to connect to your servers to configure them.

    ```
    ssh-keygen -f ~/.ssh/cherry
    ```

    This will create `~/.ssh/cherry` and ~/.ssh/cherry.pub`

    This is the SSH key you will use in order to SSH into your Cherry Server and use with Ansible.  
    
    You can configure your ~/.ssh/config to use this new key with the IP addresses for your servers that we will create further below.

- While we're add it.  We're going to create a second SSH key that will be used by Hadoop and Spark.  
    Hadoop and Spark master servers SSH into the slaves within their cluster in order to manage them.  
    
    Our Ansible playbooks will upload this second SSH key to the new servers we create and allow the `hadoop` and `spark` users to SSH using this key. 
    
    When generating this second key, have it save to the ansible directory here.

    ```
    cd this/directory
    ssh-keygen -f files/test-key
    ```

    This will create `ansible/files/test-key` and `ansible/files/test-key.pub`

- The Cluster should now be ready and you will be able to access the admin panels via:

    Hadoop UI: [http://cluster_master_ip:50700]()

    Spark UI: [http://cluster_master_ip:8080]()
