#
# Cookbook Name:: kkafka
# Recipe:: _setup
#

# group node['kkafka']['group'] do
#   only_if { node['kkafka']['manage_user'] }
# end

# user node['kkafka']['user'] do
#   gid node['kkafka']['group']
#   home '/var/empty/kafka'
#   shell '/sbin/nologin'
#   only_if { node['kkafka']['manage_user'] }
# end

[
  node['kkafka']['version_install_dir'],
  #Let the log dir be created automatically when Kafka starts up
  #otherwise it is created before the symlink
  #node['kkafka']['log_dir'],
  node['kkafka']['build_dir'],
].each do |dir|
  directory dir do
    owner node['kkafka']['user']
    group node['kkafka']['group']
    mode '755'
    recursive true
  end
end

kafka_log_dirs.each do |dir|
  directory dir do
    owner node['kkafka']['user']
    group node['kkafka']['group']
    mode '755'
    recursive true
  end
end
