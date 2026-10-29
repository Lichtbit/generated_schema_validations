# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 'bundler/setup'
require 'rails'
require 'active_record'
require 'generated_schema_validations'
require 'generated_schema_validations/dumper'
require 'generated_schema_validations/dump_checker'
require 'generated_schema_validations/table'

# Runs with SQLite by default. Set DATABASE_URL to run the PostgreSQL specs too.
ActiveRecord::Base.establish_connection(ENV.fetch('DATABASE_URL', 'sqlite3::memory:'))
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
