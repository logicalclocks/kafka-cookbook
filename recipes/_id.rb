found_id=-1
id=1
my_ip = my_private_ip()

for kafka in node[:kkafka][:default][:private_ips]
  if my_ip.eql? kafka
    Chef::Log.info "Found matching IP address in the list of kafka nodes: #{kafka}. ID= #{id}"
    found_id = id
  end
  id += 1
end 
Chef::Log.info "Found ID IS: #{found_id}"
if found_id != -1
  node.override.kkafka.broker.broker_id = found_id
  node.override.kkafka.broker.id = found_id
end

