namespace :config do
  task :symlink, roles: :app do
    ['amazon_s3.yml', 'newrelic.yml', 'despachodepan.yml'].each do |file|
      run "ln -nfs #{shared_path}/config/#{file} #{release_path}/config/#{file}"
    end
  end
  after "deploy:finalize_update", "config:symlink"
end
