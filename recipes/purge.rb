  bash 'kill_running_service' do
    user "root"
    ignore_failure true
    code <<-EOF
      service stop kafka
      systemctl stop kafka
    EOF
  end

  file "/etc/init.d/kafka" do
    action :delete
    ignore_failure true
  end
  
  file "/lib/systemd/system/kafka.service" do
    action :delete
    ignore_failure true
  end
  file "/etc/systemd/system/kafka.service" do
    action :delete
    ignore_failure true
  end
  file "/lib/systemd/system/kafka.service" do
    action :delete
    ignore_failure true
  end
  directory "/etc/systemd/system/kafka.service.d" do
    recursive true
    action :delete
    ignore_failure true
  end

  directory node['kkafka']['install_dir'] do
    recursive true
    action :delete
    ignore_failure true
  end



