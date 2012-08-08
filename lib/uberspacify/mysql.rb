Capistrano::Configuration.instance.load do

  # callbacks
  after   'deploy:setup',       'mysql:setup_database_and_config'

  # custom recipes
  namespace :mysql do
    task :setup_database_and_config do
      my_cnf = capture('cat ~/.my.cnf')
      config = {}
      %w(development production test).each do |env|
        
        config[env] = {
          'adapter' => 'mysql2',
          'encoding' => 'utf8',
          'database' => "#{fetch :user}_rails_#{fetch :application}_#{env}",
          'host' => 'localhost'
        }
        
        my_cnf.match(/^user=(\w+)/)
        config[env]['username'] = $1

        my_cnf.match(/^password=(\w+)/)
        config[env]['password'] = $1

        my_cnf.match(/^port=(\d+)/)
        config[env]['port'] = $1.to_i
        
        run "mysql -e 'CREATE DATABASE IF NOT EXISTS #{config[env]['database']} CHARACTER SET utf8 COLLATE utf8_general_ci;'"
      end
      
      run "mkdir -p #{fetch :shared_path}/config"
      put config.to_yaml, "#{fetch :shared_path}/config/database.yml"
      
    end
  end

end