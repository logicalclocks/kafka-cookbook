#
# Cookbook Name:: kkafka
# Recipe:: _configure
#

directory node.kkafka.config_dir do
  owner node.kkafka.user
  group node.kkafka.group
  mode '755'
  recursive true
end

template ::File.join(node.kkafka.config_dir, 'log4j.properties') do
  source 'log4j.properties.erb'
  owner node.kkafka.user
  group node.kkafka.group
  mode '644'
  helpers(Kafka::Log4J)
  variables({
    config: node.kkafka.log4j,
  })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end

template ::File.join(node.kkafka.config_dir, 'server.properties') do
  source 'server.properties.erb'
  owner node.kkafka.user
  group node.kkafka.group
  mode '644'
  helper :config do
    node.kkafka.broker.sort_by(&:first)
  end
  helpers(Kafka::Configuration)
  # variables({
  #   zk_ip: zk_ip
  # })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end

template kafka_init_opts[:env_path] do
  source kafka_init_opts.fetch(:env_template, 'env.erb')
  owner 'root'
  group 'root'
  mode '644'
  variables({
    main_class: 'kafka.Kafka',
  })
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end

template kafka_init_opts[:script_path] do
  source kafka_init_opts[:source]
  owner 'root'
  group 'root'
  mode kafka_init_opts[:permissions]
  variables({
    daemon_name: 'kafka',
    port: node.kkafka.broker.port,
    user: node.kkafka.user,
    env_path: kafka_init_opts[:env_path],
    ulimit: node.kkafka.ulimit_file,
    kill_timeout: node.kkafka.kill_timeout,
  })
  helper :controlled_shutdown_enabled? do
    !!fetch_broker_attribute(:controlled, :shutdown, :enable)
  end
  if restart_on_configuration_change?
    notifies :create, 'ruby_block[coordinate-kafka-start]', :immediately
  end
end


remote_file "#{node.kkafka.install_dir}/libs/KafkaAclAuthorizer-1.0.jar" do
  user 'root'
  group 'root'
  source "http://snurran.sics.se/hops/KafkaAclAuthorizer-1.0.jar"
  mode 0755
  action :create_if_missing
end


include_recipe node.kkafka.start_coordination.recipe
