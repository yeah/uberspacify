require 'capistrano_colors'
require 'rvm/capistrano'
require 'bundler/capistrano'

def abort_red(msg)
  abort "  * \e[#{1};31mERROR: #{msg}\e[0m"
end

Capistrano::Configuration.instance.load do

  # required variables
  _cset(:user)                  { abort_red "Please configure your Uberspace user in config/deploy.rb using 'set :user, <username>'" }
  _cset(:repository)            { abort_red "Please configure your code repository config/deploy.rb using 'set :repository, <repo uri>'" }

  # optional variables
  _cset(:domain)                { nil }
  _cset(:passenger_port)        { rand(61000-32768+1)+32768 } # random ephemeral port

  _cset(:deploy_via)            { :remote_cache }
  _cset(:git_enable_submodules) { 1 }
  _cset(:branch)                { 'master' }

  _cset(:keep_releases)         { 3 }

  # uberspace presets
  set(:deploy_to)               { "/var/www/virtual/#{user}/rails/#{application}" }
  set(:home)                    { "/home/#{user}" }
  set(:use_sudo)                { false }
  set(:rvm_type)                { :user }
  set(:rvm_install_ruby)        { :install }
  set(:rvm_ruby_string)         { "ree@rails-#{application}" }

  ssh_options[:forward_agent] = true
  default_run_options[:pty]   = true

  # callbacks
  before  'deploy:setup',           'rvm:install_rvm'
  before  'deploy:setup',           'rvm:install_ruby'
  after   'deploy:setup',           'uberspace:setup_svscan'
  after   'deploy:setup',           'daemontools:setup_daemon'
  after   'deploy:setup',           'apache:setup_reverse_proxy'
  before  'deploy:finalize_update', 'deploy:symlink_shared'
  after   'deploy',                 'deploy:cleanup'

  # custom recipes
  namespace :uberspace do
    task :setup_svscan do
      run 'uberspace-setup-svscan ; echo 0'
    end
  end

  namespace :daemontools do
    task :setup_daemon do
      daemon_script = <<-EOF
#!/bin/bash
export HOME=#{fetch :home}
source $HOME/.bash_profile
cd #{fetch :deploy_to}/current
rvm use #{fetch :rvm_ruby_string}
exec bundle exec passenger start -p #{fetch :passenger_port} -e production 2>&1
      EOF

      log_script = <<-EOF
#!/bin/sh
exec multilog t ./main
      EOF

      run                 "mkdir -p #{fetch :home}/etc/run-rails-#{fetch :application}"
      run                 "mkdir -p #{fetch :home}/etc/run-rails-#{fetch :application}/log"
      put daemon_script,  "#{fetch :home}/etc/run-rails-#{fetch :application}/run"
      put log_script,     "#{fetch :home}/etc/run-rails-#{fetch :application}/log/run"
      run                 "chmod +x #{fetch :home}/etc/run-rails-#{fetch :application}/run"
      run                 "chmod +x #{fetch :home}/etc/run-rails-#{fetch :application}/log/run"
      run                 "ln -nfs #{fetch :home}/etc/run-rails-#{fetch :application} #{fetch :home}/service/rails-#{fetch :application}"

    end
  end

  namespace :apache do
    task :setup_reverse_proxy do
      htaccess = <<-EOF
RewriteEngine On
RewriteRule ^(.*)$ http://localhost:#{fetch :passenger_port}/$1 [P]
      EOF
      path = fetch(:domain) ? "/var/www/virtual/#{fetch :user}/#{fetch :domain}" : "#{fetch :home}/html"
      run                 "mkdir -p #{path}"
      put htaccess,       "#{path}/.htaccess"
      run                 "chmod +r #{path}/.htaccess"
      run                 "uberspace-add-domain -qwd #{fetch :domain} ; true" if fetch(:domain)
    end
  end

  namespace :deploy do
    desc "Displays status information of the application."
    task :status do
      run "svstat #{fetch :home}/service/rails-#{fetch :application}"
    end
    task :start do
      run "svc -u #{fetch :home}/service/rails-#{fetch :application}"
    end
    task :stop do
      run "svc -d #{fetch :home}/service/rails-#{fetch :application}"
    end
    task :restart do
      run "svc -du #{fetch :home}/service/rails-#{fetch :application}"
    end

    task :symlink_shared do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    end
  end

end
