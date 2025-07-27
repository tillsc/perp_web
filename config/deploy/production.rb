# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server "perp.de", user: "perp.de", roles: %w{app db web}
# server "example.com", user: "deploy", roles: %w{app web}, other_property: :other_value
# server "db.example.com", user: "deploy", roles: %w{db}

set :rbenv_path, '/usr/lib/x86_64-linux-gnu/rbenv/libexec/rbenv'
set :rbenv_prefix, "RBENV_ROOT=/var/www/vhosts/perp.de/.rbenv #{fetch(:rbenv_path)} exec"
# set :rbenv_ruby, '3.2.2'

set :passenger_restart_with_touch, true

before 'bundler:install', 'bundler:set_groups'
before 'bundler:install', 'bundler:force_ruby_platform'

namespace :bundler do
  task :set_groups do
    on roles(:app) do
      within release_path do
        # Install only the mysql group, skip others like postgres
        execute :bundle, 'config set --local with mysql'
        execute :bundle, 'config set --local without development test postgres'
      end
    end
  end

  task :force_ruby_platform do
    on roles(:app) do
      within release_path do
        execute :bundle, 'config set force_ruby_platform true' # Fixes problems with GLIBC on old linux machine
      end
    end
  end
end

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}



# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.



# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server "example.com",
#   user: "user_name",
#   roles: %w{web app},
#   ssh_options: {
#     user: "user_name", # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: "please use keys"
#   }
