include_recipe "deploy"
include_recipe "nginx-app::server"

instance_roles = node[:scalarium][:instance][:roles]
cluster_name   = node[:scalarium][:cluster][:name]
app_access_log = "off"

# need to do this better
node[:docroot] = 'www'

node[:deploy].each do |application, deploy|

  case application
  when 'easybib'
    if !['EasyBib', 'EasyBib Playground', 'Fruitkid'].include?(cluster_name)
      next
    end
    if !instance_roles.include?('nginxphpapp') && !instance_roles.include?('testapp')
      next
    end

  when 'easybib_api'
    next unless instance_roles.include?('bibapi')

  when 'sitescraper'
    next unless instance_roles.include?('sitescraper')

  when 'research_app'
    next unless cluster_name == 'Research Cloud'
    next unless instance_roles.include?('nginxphpapp')

  else
    Chef::Log.debug("Skipping nginx-app::configure for app #{application}")
    next
  end

  template "/etc/nginx/sites-enabled/easybib.com.conf" do
    source "easybib.com.conf.erb"
    mode   "0755"
    owner  node["nginx-app"][:user]
    group  node["nginx-app"][:group]
    variables(
      :js_alias    => node["nginx-app"][:js_modules],
      :img_alias   => node["nginx-app"][:img_modules],
      :css_alias   => node["nginx-app"][:css_modules],
      :access_log  => app_access_log,
      :deploy      => deploy,
      :application => application
    )
    notifies :restart, resources(:service => "nginx"), :delayed
  end

end

include_recipe "php-fpm::service"
