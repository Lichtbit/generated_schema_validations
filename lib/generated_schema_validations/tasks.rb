# frozen_string_literal: true

Rake::Task['db:schema:dump'].enhance do
  require 'generated_schema_validations'
  require_relative 'dumper'
  require_relative 'table'
  GeneratedSchemaValidations::Dumper.generate
end

namespace :db do
  desc 'Dump validations to stdout'
  task validation_dump_direct: :environment do
    require 'generated_schema_validations'
    require_relative 'dumper'
    require_relative 'dump_checker'
    require_relative 'table'

    GeneratedSchemaValidations::DumpChecker.generate
  end
end
