directory '/var/local/jukin-install-states' do
  action :create
end

bash 'get_noderepo' do
  code <<-EOH
    curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -
    EOH
  not_if { ::File.exist?('/var/local/jukin-install-states/elasticsearch-nodejs_installed') }
end

packages = %w(curl tree nodejs)

packages.each do |pkg|
  package pkg do
    action :install
  end
end

bash 'get_elasticdump' do
  code <<-EOH
    npm install elasticdump -g
    EOH
  not_if { ::File.exist?('/var/local/jukin-install-states/elasticsearch-nodejs_installed') }
  notifies :create, 'file[/var/local/jukin-install-states/elasticsearch-nodejs_installed]', :immediate
end

file '/var/local/jukin-install-states/elasticsearch-nodejs_installed' do
  user 'root'
  group 'root'
  mode '0444'
  action :nothing
end
