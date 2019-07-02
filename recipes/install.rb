group node['kkafka']['group'] do
  action :create
  not_if "getent group #{node['kkafka']['group']}"
end

user node['kkafka']['user'] do
  action :create
  gid node['kkafka']['group']
  home "/home/#{node['kkafka']['user']}"
  shell "/bin/bash"
  manage_home true
  system true
  not_if "getent passwd #{node['kkafka']['user']}"
end

group node['kagent']['certs_group'] do
  action :create
  not_if "getent group #{node['kagent']['certs_group']}"
end

group node['kagent']['certs_group'] do
  action :modify
  members ["#{node['kkafka']['user']}"]
  append true
end

[
  node['kkafka']['version_install_dir'],
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
    mode '770'
    action :create
    recursive true
    not_if { File.directory?(dir) }
  end
end


kkafka_download kafka_local_download_path do
  source node['kkafka']['download_url']
  checksum node['kkafka']['checksum']
  md5_checksum node['kkafka']['md5_checksum']
  not_if { kafka_installed? }
end

execute 'extract-kafka' do
  cwd node['kkafka']['build_dir']
  command <<-EOH.gsub(/^\s+/, '')
    tar zxf #{kafka_local_download_path} && \
    chown -R #{node['kkafka']['user']}:#{node['kkafka']['group']} #{node['kkafka']['build_dir']}
  EOH
  not_if { kafka_installed? }
end

kkafka_install node['kkafka']['version_install_dir'] do
  from kafka_target_path
  not_if { kafka_installed? }
end
