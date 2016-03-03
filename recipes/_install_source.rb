include_recipe 'build-essential'
include_recipe 'git::default'

case node['platform_family']
when 'debian'
  include_recipe 'apt::default'

  # needed to generate deb package
  package 'devscripts'
  package 'python-support'
  package 'python-configobj'
  package 'python-mock'
  package 'cdbs'
when 'rhel'
  include_recipe 'yum::default'

  package 'python-configobj'
  package 'rpm-build'
end


# TODO: move source directory to an attribute
git node['diamond']['source_path'] do
  repository node['diamond']['source_repository']
  reference node['diamond']['source_reference']
  action :sync
  notifies :run, 'execute[build diamond]', :immediately
end


case node['platform_family']
when 'debian'
  execute 'build diamond' do
    command "cd #{node['diamond']['source_path']};make builddeb"
    action :nothing
    notifies :run, 'execute[install diamond]', :immediately
  end


  execute 'install diamond' do
    command "cd #{node['diamond']['source_path']};dpkg -i build/diamond_*_all.deb"
    action :nothing
    notifies :restart, 'service[diamond]'
  end

else
  # TODO: test this
  execute 'build diamond' do
    command "cd #{node['diamond']['source_path']};make rpm"
    action :nothing
    notifies :run,"ruby_block[find_rpm_file]", :immediately
    notifies :install ,"rpm_package[diamond]", :immediately
  end


ruby_block "find_rpm_file"  do
block do
  Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)   
  command ='ls /usr/local/share/diamond_src/dist/*.noarch.rpm |head -1'
  command_out = shell_out(command)
  node.set['diamond_rpm_file'] = command_out.stdout

end
action :nothing
end


rpm_package 'diamond' do
    source node['diamond_rpm_file']
    action :nothing
    notifies :restart, 'service[diamond]'
 end

end


