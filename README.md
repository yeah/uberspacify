# Uberspacify

Uberspacify helps you deploy a Ruby on Rails app on Uberspace, a popular German shared hosting provider.

All the magic is built into a couple nice Capistrano scripts. Uberspacify will create an environment for your app, install Passenger, run it in standalone mode, monitor it using Daemontools, and configure Apache to reverse-proxy to it. Uberspacify will also find out your Uberspace MySQL password and create databases as well as a `database.yml`

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'uberspacify'
```

And then execute:

    $ bundle
    
This should install uberspacify as well as Capistrano and some other gems for you.

Now execute the following to get a `Capfile` and a `deploy.rb`:

    $ capify .
    
If you are using Rails' asset pipeline, add this line to your `Capfile`:

```ruby
load 'deploy/assets'
```
    
Now, you need to add a few lines regarding your Uberspace to your `config/deploy.rb`. It is safe to copy, paste & adapt the following:

```ruby
require 'uberspacify/recipes'

# the Uberspace server you are on
server 'phoenix.uberspace.de', :web, :app, :db, :primary => true

# your Uberspace username
set :user, 'cappy'

# a name for your app, [a-z0-9] should be safe, will be used for your gemset,
# databases, directories, etc.
set :application, 'dummyapp'

# the repo where your code is hosted
set :scm, :git
set :repository, 'https://github.com/yeah/dummyapp.git'

# optional stuff from here

# By default, your app will be available in the root of your Uberspace. If you
# have your own domain set up, you can configure it here
# set :domain, 'www.dummyapp.com'

# By default, uberspacify will generate a random port number for Passenger to
# listen on. This is fine, since only Apache will use it. Your app will always
# be available on port 80 and 443 from the outside. However, if you'd like to
# set this yourself, go ahead.
# set :passenger_port, 55555
```

Done. That was the hard part. It's easy from here on out. Next, add all new/modified files to version control. If you use Git, the following will do:

    $ git add . ; git commit -m 'uberspacify my app!' ; git push
    
And here comes the fun part - get it all up and running on Uberspace! These commands should teleport your app to the Uberspace (execute them one by one and keep an eye on the output):

    $ bundle exec cap deploy:setup
    $ bundle exec cap deploy:migrations
    
(Be sure to have your public key set up on your Uberspace account already.)
    
This will do a whole lot of things, so don't get nervous, it takes some time. After Capistrano is done, **please wait some more**. When Passenger starts for the first time, it will actually compile an nginx server. Don't worry though, subsequent starts will be fast.

Now, **after some time**, your app should be available on your Uberspace URI.

Should you ever need to stop/start/restart your app, you can do so using Capistrano's standard:

    $ bundle exec cap deploy:{stop|start|restart}
    
That's it folks. Have fun.
    


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
