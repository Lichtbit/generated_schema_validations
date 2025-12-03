# frozen_string_literal: true

class GeneratedSchemaValidations::DumpChecker < GeneratedSchemaValidations::Dumper
  def self.read_schema_content
    stream = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.rewind
    stream.read
  end

  def write_schema_validations(template_ruby)
    puts template_ruby
  end
end
