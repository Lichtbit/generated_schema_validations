# frozen_string_literal: true

class GeneratedSchemaValidations::DumpChecker < GeneratedSchemaValidations::Dumper
  def self.read_schema_content
    stream = StringIO.new

    if ActiveRecord::VERSION::STRING >= "7.2"
      ActiveRecord::SchemaDumper.dump(
        ActiveRecord::Base.connection_pool,
        stream
      )
    else
      ActiveRecord::SchemaDumper.dump(
        ActiveRecord::Base.connection,
        stream
      )
    end

    stream.rewind
    stream.read
  end

  def write_schema_validations(template_ruby)
    puts template_ruby
  end
end
