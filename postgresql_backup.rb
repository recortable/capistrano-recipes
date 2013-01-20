namespace :db do
  desc "Backup the production database"
  task :backup, :roles => :db do
    run "mkdir -p #{current_path}/backups"
    run "cd #{current_path}; pg_dump -U #{user} #{application}_production -f backups/#{Time.now.utc.strftime('%Y%m%d%H%M%S')}.sql"
  end

  desc "Backup the database and download the script"
  task :download, :roles => :app do
    db
    timestamp = Time.now.utc.strftime('%Y%m%d%H%M%S') 
    run "mkdir -p backups"
    run "cd #{current_path}; tar -cvzpf #{timestamp}_backup.tar.gz backups"
    get "#{current_path}/#{timestamp}_backup.tar.gz", "#{timestamp}_backup.tar.gz"
  end

  desc "Dumps target database into development db"
  task :pull do
    db = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../database.yml'))).result)
    production = db['production']

    file  = "#{application}.sql.bz2"
    remote_file = "#{shared_path}/log/#{file}"
    run "pg_dump --clean --no-owner --no-privileges -U#{production['username']} -h#{production['host']} #{production['database']} | bzip2 > #{file}" do |ch, stream, out|
      ch.send_data "#{production['password']}\n" if out =~ /^Password:/
      puts out
    end
    puts rsync = "rsync #{user}@masqueunacasa.net:#{file} tmp"
    `#{rsync}`
    development = db['development']
    puts depackage = "bzcat tmp/#{file} | psql -U#{development['username']} #{development['database']}"
    `#{depackage}`
  end

  desc "Reload the last downloaded database"
  task :reload do
    db = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../database.yml'))).result)
    development = db['development']
    #puts destroy_db = "rake db:drop db:create"
    #`#{destroy_db}`
    file  = "#{application}.sql.bz2"
    puts depackage = "bzcat tmp/#{file} | psql -U#{development['username']} #{development['database']}"
    `#{depackage}`
  end

  namespace :local do
    desc "Backup the local database"
    task :dump, roles: :db do
      db = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../database.yml'))).result)
      db = db['development']
      dump = "pg_dump --clean --no-owner --no-privileges -U#{db['username']} #{db['database']} -f tmp/db.dump.sql"
      puts dump
      `#{dump}`
    end

    desc "Load dump into local database"
    task :load_dump, roles: :db do
      db = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../database.yml'))).result)
      db = db['development']
      load_cmd = "cat tmp/db.dump.sql | psql -U#{db['username']} #{db['database']}"
      puts load_cmd
      `#{load_cmd}`
    end

    desc "Push the local database into production"
    task :push, roles: :db do
      db = YAML::load(ERB.new(IO.read(File.join(File.dirname(__FILE__), '../database.yml'))).result)
      dev = db['development']
      prod = db['production']

      puts "THIS WILL DESTROY THE PRODUCTION DATA!!!"
      name = Capistrano::CLI.ui.ask("PLEASE CONFIRM. Production database name: ")
      if name == prod['database']
        filename = "db.dump.#{Time.now.to_i}.sql.bz2"
        puts dump = "pg_dump --clean --no-owner --no-privileges -U#{dev['username']} #{dev['database']} | bzip2 > tmp/#{filename}"
        `#{dump}`

        upload "tmp/#{filename}", "#{shared_path}/#{filename}"
        run "bzcat #{shared_path}/#{filename} | psql -U#{prod['username']} #{prod['database']}"  do |ch, stream, out|
          ch.send_data "#{prod['password']}\n" if out =~ /^Password:/
          puts out
        end
        run "rm #{shared_path}/#{filename}"
        `rm tmp/#{filename}`
      else
        puts "Doesn't match #{name} <=> #{prod['database']}"
      end
    end
  end
end

