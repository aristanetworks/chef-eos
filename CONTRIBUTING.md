# Contributing to the eos Cookbook

Community contributions to this cookbook are welcome. Please ensure all Pull
Requests include appropriate tests and documentation updates.

# Contents

1. [Development environment](#development-environment)
2. [Testing](#testing)
3. [Authors & Support](#authors--support)
4. [License](#license)

# Development Environment

- Download and install the [ChefDK](https://downloads.chef.io/chef-dk/)
- `eval "$(chef shell-init bash)"`
- `gem install rbeapi`
- `git clone ...`
- `cd chef-eos`

## Guard

In a separate window, you can run Guard to analyze file changes on-write.

- `cd <path/to>/chef-eos`
- `chef gem install guard-foodcritic`
- `chef exec guard`

# Testing

Verify your environment by running the unit and kitchen tests before making
changes.

## Style checks

- `rake style`

## Unit tests

- `rake unit`

## System tests - TestKitchen

  TestKitchen requires Vagrant and VirtualBox.

- Download Vagrant VirtualBox image of vEOS from [Arista Software Download](https://www.arista.com/en/support/software-download) (Free login required).  Navigate to vEOS --> `vEOS-lab-<version>-virtualbox.box`
- Add the box to your local inventory

    ```
    vagrant box add --name vEOS-4.16.7M ~/Downloads/vEOS_4.16.7M_virtualbox.box
    ```

- Add the vEOS version to .kitchen.yml

    ```
    platforms:
      - name: vEOS-4.16.7M
        driver:
          vagrantfiles:
            - vagrantfiles/veos.rb
    ```

- Verify TestKitchen config

    ```
    $ kitchen list
    Instance         Driver   Provisioner  Verifier  Transport  Last Action
    veos-vEOS-4167M  Vagrant  ChefZero     Busser    Ssh        <Not Created>
    ```

- Until omnitruck install.sh gets updated to recognize Arista EOS, the vagrantfiles/veos.rb will download and install the latest chef-client to EOS.TestKitchen normally handles this using https://omnitruck.chef.io/install.sh.
  NOTE: This is a temporary workaround until the following 2 PRs get released:
    - https://github.com/chef/mixlib-install/pull/127
    - https://github.com/chef/omnitruck/pull/192
- Run TestKitchen
  - `kitchen create [4167M]`
  - Optional for debugging: `kitchen login [4167M]`
  - `kitchen converge [4167M]`
  - `kitchen verify [4167M]`
  - `kitchen destroy [4167M]`

# Authors & Support

For support, please open a GitHub issue.  This module is maintained by Arista
[EOS+ Consulting Services](mailto://eosplus-dev@arista.com). Commercial support
options are available upon request.

# License

All files in this package are covered by the included [license](LICENSE) unless
otherwise noted.
