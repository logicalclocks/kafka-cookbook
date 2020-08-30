#
# Cookbook Name:: kkafka
# Recipe:: _configure
#

# User certs must belong to kafka group to be able to rotate x509 material
group node['kkafka']['group'] do
  action :modify
  members node['kagent']['certs_user']
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

hopsworks_alt_url = "https://#{private_recipe_ip("hopsworks","default")}:8181" 
if node.attribute? "hopsworks"
  if node["hopsworks"].attribute? "https" and node["hopsworks"]['https'].attribute? ('port')
    hopsworks_alt_url = "https://#{private_recipe_ip("hopsworks","default")}:#{node['hopsworks']['https']['port']}"
  end
end

crypto_dir = x509_helper.get_crypto_dir(node['kkafka']['user'])
kagent_hopsify "Generate x.509" do
  user node['kkafka']['user']
  crypto_directory crypto_dir
  hopsworks_alt_url hopsworks_alt_url
  action :generate_x509
  not_if { conda_helpers.is_upgrade || node["kagent"]["enabled"] == "false" }
end

kstore_name, tstore_name = x509_helper.get_user_keystores_name(node['kkafka']['user'])
node.override['kkafka']['broker']['ssl']['keystore']['location'] = "#{crypto_dir}/#{kstore_name}"
node.override['kkafka']['broker']['ssl']['keystore']['password'] = node['hopsworks']['master']['password']
node.override['kkafka']['broker']['ssl']['key']['password'] = node['hopsworks']['master']['password']
node.override['kkafka']['broker']['ssl']['truststore']['location'] = "#{crypto_dir}/#{tstore_name}"
node.override['kkafka']['broker']['ssl']['truststore']['password'] = node['hopsworks']['master']['password']
# required, requested, none
node.override['kkafka']['broker']['ssl']['client']['auth'] = "required"

directory node['kkafka']['config_dir'] do
  owner node['kkafka']['user']
  group node['kkafka']['group']
  mode '750'
  recursive true
end

template ::File.join(node['kkafka']['config_dir'], 'log4j.properties') do
  source 'log4j.properties.erb'
  owner node['kkafka']['user']
  group node['kkafka']['group']
  mode '640'
  helpers(Kafka::Log4J)
  variables({
    config: node['kkafka']['log4j'],
  })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end

template ::File.join(node['kkafka']['config_dir'], 'server.properties') do
  source 'server.properties.erb'
  owner node['kkafka']['user']
  group node['kkafka']['group']
  mode '640'
  helper :config do
    node['kkafka']['broker'].sort_by(&:first)
  end
  helpers(Kafka::Configuration)
  # variables({
  #   zk_ip: zk_ip
  # })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end


template kafka_init_opts['env_path'] do
  source kafka_init_opts.fetch(:env_template, 'env.erb')
  owner 'root'
  group 'root'
  mode '640'
  variables({
    main_class: 'kafka.Kafka',
  })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end

file "#{node['kkafka']['config_dir']}/jmxremote.password" do 
  owner node['kkafka']['user']
  group node['kkafka']['group']
  mode '600'
  content "#{node['kkafka']['jmx_user']} #{node['kkafka']['jmx_password']}"  
end

file "#{node['kkafka']['config_dir']}/jmxremote.access" do 
  owner node['kkafka']['user']
  group node['kkafka']['group']
  mode '600'
  content "#{node['kkafka']['jmx_user']} readwrite" 
end

cookbook_file "#{node['kkafka']['config_dir']}/kafka.yaml" do
  owner node['kkafka']['user']
  group node['kkafka']['group']
  source 'kafka.yaml'
  mode '0750'
  action :create
end

deps = ""
if exists_local("kzookeeper", "default")
  deps = "zookeeper.service"
end
if exists_local("ndb", "mysqld")
  deps += " mysqld.service"
end

template kafka_init_opts['script_path'] do
  source kafka_init_opts['source']
  owner 'root'
  group 'root'
  mode kafka_init_opts['permissions']
  variables({
    deps: deps,              
    daemon_name: 'kafka',
    port: node['kkafka']['broker']['port'],
    user: node['kkafka']['user'],
    env_path: kafka_init_opts['env_path'],
    ulimit: node['kkafka']['ulimit_file'],
    kill_timeout: node['kkafka']['kill_timeout'],
  })
  helper :controlled_shutdown_enabled? do
    !!fetch_broker_attribute(:controlled, :shutdown, :enable)
  end
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end


remote_file "#{node['kkafka']['install_dir']}/libs/hops-kafka-authorizer-#{node['kkafka']['authorizer_version']}.jar" do
  source node['kkafka']['authorizer_download_url']
  user 'root'
  group 'root'
  mode 0755
  action :create_if_missing
end


include_recipe node['kkafka']['start_coordination']['recipe']
