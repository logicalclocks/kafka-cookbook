#
# Cookbook Name:: kkafka
# Attributes:: default
#

#
# Version of Kafka to install.
default.kkafka.version = '0.9.0.1'

#
# Base URL for Kafka releases. The recipes will a download URL using the
# `base_url`, `version` and `scala_version` attributes.
default.kkafka.base_url = 'https://archive.apache.org/dist/kafka'
#default.kkafka.base_url = 'http://snurran.sics.se/hops'
#
# SHA-256 checksum of the archive to download, used by Chef's `remote_file`
# resource.
default.kkafka.checksum = '7f3900586c5e78d4f5f6cbf52b7cd6c02c18816ce3128c323fd53858abcf0fa1'

#
# MD5 checksum of the archive to download, which will be used to validate that
# the "correct" archive has been downloaded.
default.kkafka.md5_checksum = ''

#
# Scala version of Kafka.
default.kkafka.scala_version = '2.10'

#
# Directory where to install Kafka.
default.kkafka.install_dir = '/opt/kafka'

#
# Directory where to install *this* version of Kafka.
# For actual default value see `_defaults` recipe.
default.kkafka.version_install_dir = nil

#
# Directory where the downloaded archive will be extracted to.
default.kkafka.build_dir = ::File.join(Dir.tmpdir, 'kafka-build')

#
# Directory where to store logs from Kafka.
default.kkafka.log_dir = '/var/log/kafka'

#
# Directory where to keep Kafka configuration files. For the
# actual default value see `_defaults` recipe.
default.kkafka.config_dir = nil

#
# JMX port for Kafka.
default.kkafka.jmx_port = 19999

#
# JMX configuration options for Kafka.
default.kkafka.jmx_opts = %w[
  -Dcom.sun.management.jmxremote
  -Dcom.sun.management.jmxremote.authenticate=false
  -Dcom.sun.management.jmxremote.ssl=false
].join(' ')

#
# User for directories, configuration files and running Kafka.
default.kkafka.user = 'kafka'

#
# Should node.kkafka.user and node.kkafka.group be created?
default.kkafka.manage_user = true

#
# Group for directories, configuration files and running Kafka.
default.kkafka.group = 'kafka'

#
# JVM heap options for Kafka.
default.kkafka.heap_opts = '-Xmx4G -Xms1G'

#
# Generic JVM options for Kafka.
default.kkafka.generic_opts = nil

#
# GC log options for Kafka. For the actual default value
# see `_defaults` recipe.
default.kkafka.gc_log_opts = nil

#
# JVM Performance options for Kafka.
default.kkafka.jvm_performance_opts = %w[
  -server
  -XX:+UseCompressedOops
  -XX:+UseParNewGC
  -XX:+UseConcMarkSweepGC
  -XX:+CMSClassUnloadingEnabled
  -XX:+CMSScavengeBeforeRemark
  -XX:+DisableExplicitGC
  -Djava.awt.headless=true
].join(' ')

#
# The type of "init" system to install scripts for. Valid values are currently
# :sysv, :systemd and :upstart.
default.kkafka.init_style = :systemd

#
# The ulimit file limit.
# If this value is not set, Kafka will use whatever the system default is.
# Depending on your system setup you might want to set this to a rather high
# value, or you will most likely run into issues with Kafka simply dying for no
# particular reason as it needs to keep a lot of file handles for socket
# connections and log files for all partitions.
default.kkafka.ulimit_file = 65535

#
# Automatically start kkafka service.
default.kkafka.automatic_start = true

#
# Automatically restart kkafka on configuration change.
# This also implies `automatic_start` even if it's set to `false`.
# The reason for this is that I can see the need for automatically starting
# Kafka if it's not running, but not necessarily restart on configuration
# changes.
default.kkafka.automatic_restart = true

#
# Attribute to set the recipe to used to coordinate Kafka service start
# if nothing is set the default recipe "_coordiante" will be used
# Refer to issue #58 for details.
default.kkafka.start_coordination.recipe = 'kkafka::_coordinate'

#
# Attribute to set the timeout in seconds when stopping the broker
# before sending SIGKILL (or equivalent).
default.kkafka.kill_timeout = 10

#
# `broker` namespace for configuration of a broker.
# Initially set to an empty Hash to avoid having `fetch(:broker, {})`
# statements in helper methods and the alike.
default.kkafka.broker = {}

#
# Root logger level and appender.
default.kkafka.log4j.root_logger = 'INFO, kafkaAppender'

#
# Appender definitions for various Kafka classes.
default.kkafka.log4j.appenders = {
  'kafkaAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { %(#{node.kkafka.log_dir}/kafka.log) },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'stateChangeAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { %(#{node.kkafka.log_dir}/kafka-state-change.log) },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'requestAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { %(#{node.kkafka.log_dir}/kafka-request.log) },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
  'controllerAppender' => {
    type: 'org.apache.log4j.DailyRollingFileAppender',
    date_pattern: '.yyyy-MM-dd',
    file: lazy { %(#{node.kkafka.log_dir}/kafka-controller.log) },
    layout: {
      type: 'org.apache.log4j.PatternLayout',
      conversion_pattern: '[%d] %p %m (%c)%n',
    },
  },
}

#
# Logger definitions.
default.kkafka.log4j.loggers = {
  'org.IOItec.zkclient.ZkClient' => {
    level: 'INFO',
  },
  'kafka.network.RequestChannel$' => {
    level: 'WARN',
    appender: 'requestAppender',
    additivity: false,
  },
  'kafka.request.logger' => {
    level: 'WARN',
    appender: 'requestAppender',
    additivity: false,
  },
  'kafka.controller' => {
    level: 'INFO',
    appender: 'controllerAppender',
    additivity: false,
  },
  'state.change.logger' => {
    level: 'INFO',
    appender: 'stateChangeAppender',
    additivity: false,
  },
}
