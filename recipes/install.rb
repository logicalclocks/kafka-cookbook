# Nothing to do during install phase...

user node.kkafka.user do
  action :create
  home "/home/#{node.kkafka.user}"
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node.kkafka.user}"
end

group node.kkafka.group do
  action :modify
  members ["#{node.kkafka.user}"]
  append true
end
