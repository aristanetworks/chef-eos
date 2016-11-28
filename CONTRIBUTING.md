# Contributing to the eos Cookbook

Community contributions to this cookbook are welcome. Please ensure all Pull
Requests include appropriate tests and documentation updates.

# Contents

1. [Development environment](#development-environment)
2. [Authors & Support](#authors--support)
3. [License](#license)

# Development Environment

- Download and install the [ChefDK](https://downloads.chef.io/chef-dk/)
- `eval "$(chef shell-init bash)"`
- `gem install rbeapi`
- `git clone ...`
- `cd chef-eos`

See [testing](TESTING.md) for details of testing changes.

## Guard

In a separate window, you can run Guard to analyze file changes on-write.

- `cd <path/to>/chef-eos`
- `chef gem install guard-foodcritic`
- `chef exec guard`

# Authors & Support

For support, please open a GitHub issue.  This module is maintained by Arista
[EOS+ Consulting Services](mailto://eosplus-dev@arista.com). Commercial support
options are available upon request.

# License

All files in this package are covered by the included [license](LICENSE) unless
otherwise noted.
