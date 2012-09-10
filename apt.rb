# https://github.com/kronn/capistrano-recipes/blob/master/sysadmin.rb
namespace :apt do
  desc "Update packagelist for aptitude"
  task :update do
    sudo "aptitude update"
    sudo "aptitude -y -s -V -Z safe-upgrade"
  end

  desc "Upgrade packages as recommended by aptitude"
  task :upgrade do
    sudo "sudo aptitude -y safe-upgrade"
  end
end

