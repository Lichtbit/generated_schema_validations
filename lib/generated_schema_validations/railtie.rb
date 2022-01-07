# frozen_string_literal: true

require 'generated_schema_validations'
require 'rails'

class GeneratedSchemaValidations::Railtie < Rails::Railtie
  rake_tasks do
    load 'generated_schema_validations/tasks.rb'
  end
end
