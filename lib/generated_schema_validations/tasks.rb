# frozen_string_literal: true

Rake::Task['db:schema:dump'].enhance do
  require 'generated_schema_validations'
  require_relative 'dumper'
  require_relative 'table'
  GeneratedSchemaValidations::Dumper.generate
end
