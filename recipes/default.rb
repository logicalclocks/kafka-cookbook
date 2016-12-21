
case node.platform
when "ubuntu"
 if node.platform_version.to_f <= 14.04
    node.override.kkafka.init_style = :sysv
 end
end


include_recipe 'kkafka::_id'

include_recipe "java"

node.default.kkafka.broker[:log_dirs] = %w[/tmp/kafka-logs]

include_recipe 'kkafka::_defaults'
include_recipe 'kkafka::_setup'
include_recipe 'kkafka::_install'


group node.kagent.certs_group do
  action :modify
  members ["#{node.kkafka.user}"]
  append true
end


#zk_ips = node.kzookeeper.default[:private_ips].join(:":2181/kafka,") 
#zk_ips = "#{zk_ips}:2181/kafka"
#node.override.kkafka.broker.zookeeper.connect = ["#{zk_ips}"]
zk_ip = private_recipe_ip('kzookeeper', 'default')
node.override.kkafka.broker.zookeeper.connect = ["#{zk_ip}:2181"]
my_ip = my_private_ip()
node.override.kkafka.broker.host.name = my_ip
#node.override.kkafka.broker.advertised.host.name = my_ip
node.override.kkafka.broker.listeners = "SSL://#{my_ip}:9091"

include_recipe 'kkafka::_configure'

include_recipe 'kkafka::_start'


if node.kagent.enabled == "true" 
  kagent_config "kafka" do
    service "kafka"
    log_file "/var/logs/kafka/kafka.log"
  end
end


#
# Disable kafka service, if node.services.enabled is not set to true
#
if node.services.enabled != "true"

  case node.platform
  when "ubuntu"
    if node.platform_version.to_f <= 14.04
      node.override.kkafka.systemd = "false"
    end
  end

  if node.kkafka.systemd == "true"

    service service_name do
      provider Chef::Provider::Service::Systemd
      supports :restart => true, :stop => true, :start => true, :status => true
      action :disable
    end

  else #sysv

    service service_name do
      provider Chef::Provider::Service::Init::Debian
      supports :restart => true, :stop => true, :start => true, :status => true
      action :disable
    end
  end

end
