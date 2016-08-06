bash "restart_kafka" do
    user "root"
    code <<-EOF
    service kafka restart
EOF
end
