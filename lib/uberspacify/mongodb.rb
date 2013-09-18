Capistrano::Configuration.instance.load do

  # callbacks
  after   'deploy:setup',       'mongo:setup_database_and_config'
  after   'deploy',             'mongo:configure_project_for_database'

  set(:mongoid_path) { "#{fetch :home}/mongoid.yml" }
  # custom recipes
  namespace :mongo do
    task :setup_database_and_config do
      # ensure that mongo is not already set up
      unless capture("if [ -e '#{fetch :mongoid_path}' ]; then echo -n 'true'; fi") == 'true'
        # set up mongo db and capture admin access information
        admin_access = capture('uberspace-setup-mongodb | grep Portnum# -A 2')
        config = {}
        config[:password] = admin_access[/Password:.+/]['Password: '.length..-2] # cut the \r that is captured at end of line
        #config[:password] = admin_access[/Password:.+/]['Password: '.length..-1]
        config[:port] = Integer(admin_access[/[0-9]{5}/]) 
        config[:user] = admin_access[/\S+_mongoadmin/]
        # generate a db user password and the db user
        user_password = (0...8).map{ (('a'..'z').to_a+('A'..'Z').to_a)[rand(54)] }.join
        run(
          "mongo admin --port #{config[:port]}" +
          " -u #{config[:user]}" +
          " -p #{config[:password]}" +
          " --eval \"db.getSiblingDB('pixel-to-go')" +
          ".addUser({user:'locomotive'," +
          "pwd:'#{user_password}'," +
          "roles:['readWrite','dbAdmin']});\""
        )
        # write to $HOME/mongoid.yml
        mongoid = {'production' => {'sessions' => {'default' => {} }}}
        access_data = mongoid['production']['sessions']['default']
        access_data['database'] = 'pixel-to-go'
        access_data['hosts'] = ["localhost:#{config[:port]}"]
        access_data['username'] = 'locomotive'
        access_data['password'] = user_password
        put mongoid.to_yaml, mongoid_path
      end
    end

    task :configure_project_for_database do
      if capture("if [ -e '#{fetch :mongoid_path}' ]; then echo -n 'true'; fi") == 'true'
        run("cp #{fetch :mongoid_path} #{fetch :deploy_to}/current/config/mongoid.yml")
      end
    end
  
  end

end