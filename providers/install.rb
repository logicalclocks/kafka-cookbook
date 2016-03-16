#
# Cookbook Name:: kkafka
# Provider:: install
#

use_inline_resources

action :run do
  execute 'install-kkafka' do
    command %(cp -rp #{::File.join(new_resource.from, '*')} #{new_resource.to})
  end

  execute 'remove-kkafka-build' do
    command %(rm -rf #{new_resource.from})
  end

  link node.kkafka.install_dir do
    owner node.kkafka.user
    group node.kkafka.group
    to node.kkafka.version_install_dir
  end

  new_resource.updated_by_last_action(true)
end
