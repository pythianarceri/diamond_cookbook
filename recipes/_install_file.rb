case node['platform_family']
when 'debian'
  dpkg_package 'diamond' do
    source node['diamond']['source_path']
    action :install
    version node['diamond']['version']
    notifies :restart, 'service[diamond]'
  end

when 'rhel'

cookbook_file "#{Chef::Config[:file_cache_path]}/diamond.noarch.rpm" do
  source "diamond-#{node["diamond"]["version"]}-0.noarch.rpm"
  action :create_if_missing
end

  yum_package 'diamond' do
    action :install
    source "#{Chef::Config[:file_cache_path]}/diamond.noarch.rpm"
    version node['diamond']['version']
    notifies :restart, 'service[diamond]'
  end
end
