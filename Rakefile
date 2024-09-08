# frozen_string_literal: true

namespace :run do
  desc 'Run Collecting Infos from Github'

  task :config do
    require_relative './init.rb'

    def app = CodePraise::App
  end

  task :dev => :config do
    app.run
  end

  task :single => :config do
    app.single
  end

  task :export => :config do
    require 'csv'
    app.export
  end
end

namespace :worker do
  namespace :run do
    desc 'Run the background worker in development mode'
    task :dev => :config do
      sh 'RACK_ENV=development bundle exec shoryuken -r ./workers/collect_repo_info_worker.rb -C ./workers/shoryuken_dev.yml'
    end

    task :dead => :config do
      sh 'RACK_ENV=development bundle exec shoryuken -r ./workers/collect_repo_info_worker.rb -C ./workers/shoryuken_dead.yml'
    end
  end
end

namespace :db do
  task :config do
    require 'sequel'
    require_relative 'config/environment' # load config info
    require_relative 'spec/helpers/database_helper'

    def app = CodePraise::App
  end

  desc 'Run migrations'
  task :migrate => :config do
    Sequel.extension :migration
    puts "Migrating #{app.environment} database to latest"
    Sequel::Migrator.run(app.DB, 'app/infrastructure/database/migrations')
  end

  desc 'Reset dev or test database'
  task :reset => :config do
    if app.environment == :production
      puts 'Cannot reset production database!'
      return
    end

    require_relative 'spec/helpers/database_helper.rb'
    DatabaseHelper.reset_database
  end
end
desc 'Run application console'
task :console do
  sh 'pry -r ./load_all'
end


