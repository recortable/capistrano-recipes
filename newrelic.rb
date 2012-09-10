set_required(:newrelic_license_key)
set_default(:newrelic_app_name) { application }

namespace :newrelic do

  desc "Setup newrelic configuration for this application"
  task :setup, roles: :web do
    run "mkdir -p #{shared_path}/config"
    template "newrelic.yml.erb", "#{shared_path}/config/newrelic.yml"
  end
  after "deploy:setup", "newrelic:setup"

  desc "Symlink the newrelic.yml file into latest release"
  task :symlink, roles: :app do
    run "ln -nfs #{shared_path}/config/newrelic.yml #{release_path}/config/newrelic.yml"
  end
  after "deploy:finalize_update", "newrelic:symlink"
end

require 'new_relic/recipes'

# We need to run this after our collector mongrels are up and running
# This goes out even if the deploy fails, sadly
after "deploy:update", "newrelic:notice_deployment"
