# Vagrant Chef Zero boilerplate

This repository encompasses some techniques for managing an infrastructure repository making use of:
- Vagrant as a tool for instantiating development environments
- Chef Zero as an orchestration tool

The example below describes how to setup a Vagrant environment with two virtual machine instances (`alfa` and `bravo`), each of which will be provisioned by Chef Zero. Each machine uses a separate Chef environment (`development` and `production` accordingly) and also makes use of a separate encrypted data bag item.

## Prerequisites

- *nix shell
- [Ruby](https://github.com/rbenv/rbenv) 2.5.x or later
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads) 5.2.x or later
- [Vagrant](https://www.vagrantup.com/downloads.html) 2.0.x or later

## Setup

```sh
$ git clone https://github.com/aspyatkin/vagrant-chef-zero-boilerplate.git
$ cd vagrant-chef-zero-boilerplate
$ script/init
```

The last command installs necessary Ruby gems along with [vagrant-helpers](https://github.com/aspyatkin/vagrant-helpers) plugin and initializes [Berkshelf](https://github.com/berkshelf/berkshelf) cookbook manager.

## Launch virtual machine instances

VM instances are declared in `opts.yaml` file. For more information refer to [vagrant-helpers](https://github.com/aspyatkin/vagrant-helpers) documentation.

```sh
$ cp opts.example.yaml opts.yaml
$ vagrant up alfa
$ vagrant up bravo
```

## Establish SSH connection to virtual machine instances

Download the [default Vagrant private key](https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant):

```sh
$ mkdir -p ~/.well-known
$ wget -O ~/.well-known/vagrant_private_key https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant
$ chmod 600 ~/.well-known/vagrant_private_key
```

Then configure SSH in `~/.ssh/config`:

```
Host alfa.example.local
  HostName 172.16.0.11
  User vagrant
  IdentityFile ~/.well-known/vagrant_private_key

Host bravo.example.local
  HostName 172.16.0.12
  User vagrant
  IdentityFile ~/.well-known/vagrant_private_key
```

`HostName` may be omitted if a server's FQDN is resolved via DNS.

Verify an instance is reachable via SSH:

```sh
$ ssh alfa.example.local
```

## Configure Chef Zero

The necessary Chef environments (`development` and `production`) are already present in the repository. For instance, a `development` environment was created with the following command:

```sh
$ script/knife environment create development
```

Since encrypted data bags will be used, encryption keys must be generated in the following fashion (each environment must have a separate key):

```sh
$ openssl rand -base64 512 | tr -d '\r\n' > ~/.well-known/chef_data_bag_secret_development
$ chmod 600 ~/.well-known/chef_data_bag_secret_development
```

Settings and paths are stored in `.env` file. Default ones may be copied from a sample:

```sh
$ cp .example.env .env
```

Needless to say that a real **production** environment key should be never left unencrypted. Consider using encrypted containers which can be mounted as a system volume.

## Manage data bags

Data bags can be created, edited or deleted with the help of `script/databag` command:

```sh
$ script/databag create test [ENVIRONMENT_NAME]
$ script/databag edit test [ENVIRONMENT_NAME]
$ script/databag delete test [ENVIRONMENT_NAME]
```

If `ENVIRONMENT_NAME` is not specified, a `KNIFE_NODE_DEFAULT_ENVIRONMENT` value from `.env` file is taken.

## Bootstrap a virtual machine instance

The following command installs Chef on an instance and provides it with an encryption key specific for its environment.

```sh
$ script/bootstrap alfa development
```

## Converge a virtual machine instance

First, add a recipe from `test` cookbook (see `local-cookbooks` folder) to a machine Chef run list:

```sh
$ script/knife node run_list add alfa test::default
```

Then, create a data bag named `test` with the following content:

```json
{
    "id": "development",
    "secret": "DO NOT TELL ANYONE"
}
```

The recipe does nothing but creates a file `/tmp/hello` containing the name of Chef environment and a secret from the `test` data bag.

At last, run `converge`:

```
$ script/converge alfa
```

To check whether `converge` has succeeded, connect to `alfa` instance and print `/tmp/hello` on the screen:

```
$ cat /tmp/hello
development
DO NOT TELL ANYONE
```

Similar steps may be performed so as to bootstrap and converge `bravo` instance. Commands will change slightly, since this instance operates in the other Chef environment (`production`).

## See also

Chef documentation:
- [knife environment](https://docs.chef.io/knife_environment.html) commands;
- [knife node](https://docs.chef.io/knife_node.html) commands;
- [data bags](https://docs.chef.io/data_bags.html).

Knife-Zero project:
- [documentation](http://knife-zero.github.io/).

## License
MIT @ [Alexander Pyatkin](https://github.com/aspyatkin)