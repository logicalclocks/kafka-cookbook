#
# Cookbook Name:: kkafka
# Recipe:: _install
#

kkafka_download kafka_local_download_path do
  source kafka_download_uri(kafka_tar_gz)
  checksum node.kkafka.checksum
  md5_checksum node.kkafka.md5_checksum
  not_if { kafka_installed? }
end

execute 'extract-kafka' do
  cwd node.kkafka.build_dir
  command <<-EOH.gsub(/^\s+/, '')
    tar zxf #{kafka_local_download_path} && \
    chown -R #{node.kkafka.user}:#{node.kkafka.group} #{node.kkafka.build_dir}
  EOH
  not_if { kafka_installed? }
end

kkafka_install node.kkafka.version_install_dir do
  from kafka_target_path
  not_if { kafka_installed? }
end
