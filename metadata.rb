name 'eos'
version '0.1.0'
chef_version '>= 12'
maintainer 'Arista EOS+ Consulting Services'
maintainer_email 'eosplus-dev@arista.com'
license 'Proprietary - All Rights Reserved'
description 'Configures Arista EOS devices'
#long_description IO.read(File.join
#  (File.dirname(__FILE__), 'README.md')
#)
source_url 'https://gishub.com/aristanetworks/chef-eos'
issues_url 'https://gishub.com/aristanetworks/chef-eos/issues'
supports 'AristaEOS', '>= 4.15.0'
depends 'ohai', '~> 4.0.0'
