Capistrano::Configuration.instance.load do

  # callbacks
  after   'deploy:setup',       'sqlite:copy_database_files'

  # custom recipes
  namespace :sqlite do
    task :copy_database_files do
      run "mkdir -p #{fetch :shared_path}/config"
      run "mv #{fetch :deploy_to}/current/config/database.yml #{fetch :shared_path}/config/database.yml"
    end
  end

end