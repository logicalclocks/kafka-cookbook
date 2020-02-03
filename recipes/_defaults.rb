#
# Cookbook Name:: kkafka
# Recipe:: _defaults
#

unless broker_attribute?(:port)
  node.default['kkafka']['broker']['port'] = 6667
end

unless node['kkafka']['gc_log_opts']
  node.default['kkafka']['gc_log_opts'] = %W[
    -Xloggc:#{node['kkafka']['log_dir']}/kafka-gc.log
    -XX:+PrintGCDateStamps
    -XX:+PrintGCTimeStamps
  ].join(' ')
end

unless node['kkafka']['config_dir']
  node.default['kkafka']['config_dir'] = ::File.join(node['kkafka']['install_dir'], 'config')
end

unless broker_attribute?(:database, :type)
  node.default['kkafka']['broker']['database']['type'] = "mysql"
end

unless broker_attribute?(:database, :url)
  mysql_host = private_recipe_ip("ndb","mysqld")
  node.default['kkafka']['broker']['database']['url'] = "#{mysql_host}:#{node['ndb']['mysql_port']}/hopsworks"
end

unless broker_attribute?(:database, :username)
  node.default['kkafka']['broker']['database']['username'] = node['hopsworks']['mysql']['users']['kafka']
end
unless broker_attribute?(:database, :password)
  node.default['kkafka']['broker']['database']['password'] = node['hopsworks']['mysql']['password']['kafka']
end
