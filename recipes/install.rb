# Nothing to do during install phase...

group node.kkafka.group do
  action :create
  not_if "getent group #{node.kkafka.group}"
end

user node.kkafka.user do
  action :create
  gid node.kkafka.group
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
