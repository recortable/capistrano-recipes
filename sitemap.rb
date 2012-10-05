# Requires gem 'sitemap_generator'
namespace :sitemap do
  desc "Generate sitemap"
  task :refresh do
    run "cd #{latest_release} && RAILS_ENV=#{rails_env} rake sitemap:refresh"
  end
end
