set_default(:config_files) { [] }

namespace :config do
  task :symlink, roles: :app do
    config_files.each do |file|
      run "ln -nfs #{shared_path}/config/#{file} #{release_path}/config/#{file}"
    end
  end
  after "deploy:finalize_update", "config:symlink"
end
