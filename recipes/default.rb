#-*- encoding : utf-8 -*-

# Create Directories
[ node['elasticsearch']['path']['conf'], node['elasticsearch']['path']['data'], node['elasticsearch']['path']['logs'], node['elasticsearch']['path']['pids'] ].each do |path|
  directory path do
    owner node['elasticsearch']['user']
    group node['elasticsearch']['user']
    mode '0755'
    recursive true
    action :create
  end
end

template "elasticsearch-env.sh" do
  path   "#{node['elasticsearch']['path']['conf']}/elasticsearch-env.sh"
  source "elasticsearch-env.sh.erb"
  owner node['elasticsearch']['user']
  group node['elasticsearch']['user']
  mode '0755'
end


# Init File
template "elasticsearch.init" do
  path   "/etc/init.d/elasticsearch"
  source "elasticsearch.init.erb"
  owner 'root'
  mode '0755'
end

# services
execute "reload-monit" do
  command "monit reload"
  action :nothing
end

elasticsearch_layer_data = search("aws_opsworks_layer", "shortname:elasticsearch").first
elasticsearch_layer_id = elasticsearch_layer_data['layer_id']
hosts = Array.new
search("aws_opsworks_instance").each do |instance|
  next unless (instance['layer_ids'].include? elasticsearch_layer_id)
  hosts.push(instance['private_ip'])
end

template "elasticsearch.yml" do
  path   "#{node['elasticsearch']['path']['conf']}/elasticsearch.yml"
  source "elasticsearch.yml.erb"
  owner node['elasticsearch']['user']
  group node['elasticsearch']['user']
  mode '0755'
  variables(
      hosts: hosts
  )
end

# Monitoring by Monit
template "elasticsearch.monitrc" do
  path   "/etc/monit.d/elasticsearch.monitrc"
  source "elasticsearch.monitrc.erb"
  owner 'root'
  mode '0755'
  notifies :run, resources(execute: "reload-monit")
end
