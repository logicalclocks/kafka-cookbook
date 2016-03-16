
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
include_recipe 'kkafka::_configure'

