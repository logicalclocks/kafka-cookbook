require 'resolv'

Chef::Recipe.send(:include, Hops::Helpers)

my_ip = my_private_ip()
my_gateway_ip = my_gateway_ip()

#
# Get all the hostsnames for all hosts in the cluster
#
all_hosts = ""
hostf = Resolv::Hosts.new
dnsr = Resolv::DNS.new
for h in node['kagent']['default']['private_ips']
  # Convert all private_ips to their hostnames
  # Kafa requires fqdns to work - won't work with IPs
  begin
    hostname = hostf.getname(h)
  rescue
    hostname = dnsr.getname(h).to_s()
  end
  all_hosts = all_hosts + "User:" + hostname + ";"
end
all_hosts = all_hosts + "User:#{node['kkafka']['user']}"
node.override['kkafka']['broker']['super']['users'] = all_hosts

include_recipe "java"
include_recipe 'kkafka::_defaults'

zk_ip = private_recipe_ip('kzookeeper', 'default')
node.override['kkafka']['broker']['zookeeper']['connect'] = ["#{zk_ip}:#{node['kzookeeper']['config']['clientPort']}"]

hostname=node['kkafka']['broker']['host']['name']
if node['kkafka']['broker']['host']['name'].eql?("")
  hostname = my_ip
  node.override['kkafka']['broker']['host']['name'] = my_ip
end

broker_port_internal = node['kkafka']['broker']['port'].to_i

if node['kkafka']['broker']['broker']['id'] == -1
  id=1
  for broker in node['kkafka']['default']['private_ips'].sort()
    if my_ip.eql? broker
      Chef::Log.info "Found matching IP address in the list of kafka nodes: #{broker}. ID= #{id}"
      node.override['kkafka']['broker']['broker']['id'] = id
      broker_port_external = broker_port_internal + id
      node.override['kkafka']['broker']['listeners'] = "INTERNAL://#{hostname}:#{broker_port_internal},EXTERNAL://#{hostname}:#{broker_port_external}"
      node.override['kkafka']['broker']['advertised']['listeners'] = "INTERNAL://#{hostname}:#{broker_port_internal},EXTERNAL://#{my_gateway_ip}:#{broker_port_external}"
    end
    id += 1
  end
end

if node['kkafka']['systemd'] == "true"
  kagent_config "kafka" do
    action :systemd_reload
  end
end

include_recipe 'kkafka::_configure'

if node['kagent']['enabled'] == "true"
  kagent_config "kafka" do
    service "kafka"
    log_file "/var/log/kafka/kafka.log"
  end
end

#
# Disable kafka service, if node['services']['enabled'] is not set to true
#
if node['services']['enabled'] != "true" && node['kkafka']['systemd'] == "true"
    service "kafka" do
      provider Chef::Provider::Service::Systemd
      supports :restart => true, :stop => true, :start => true, :status => true
      action :disable
    end

    kagent_config "kafka" do
     action :systemd_reload
    end
end

if service_discovery_enabled()
  # Register Kafka with Consul
  consul_service "Registering Kafka with Consul" do
    service_definition "kafka-consul.hcl.erb"
    action :register
  end
end
