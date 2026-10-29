# frozen_string_literal: true

require 'tempfile'

class GeneratedSchemaValidations::Dumper
  # Validators from validators/, added to the generated file only if a table uses them
  VALIDATORS = %i[date_time_in_db_range date_in_db_range time_in_db_range not_null].freeze

  def self.generate
    file = Tempfile.new(['schema', '.rb'])
    begin
      schema_content = read_schema_content.gsub(/ActiveRecord::Schema(\[[^\]]+\])?/, name)
      raise 'The schema is not well-formed.' if schema_content.include?('ActiveRecord')

      file.write(schema_content)
      file.close

      load file.path
    ensure
      file.unlink
    end
  end

  def self.read_schema_content
    File.read(Rails.root.join('db/schema.rb'))
  end

  def self.define(info = {}, &)
    new.define(info, &)
  end

  def define(info, &)
    instance_eval(&)

    template_ruby = File.read(File.expand_path('template.rb', File.dirname(__FILE__)))
    template_ruby.gsub!('VERSION_INFO', info[:version].to_s)
    indention_spaces = template_ruby.match(/( +)TABLE_VALIDATIONS/)[1]
    table_validations_ruby = @table_validations_ruby.to_s.lines.map do |line|
      line.strip.present? ? "#{indention_spaces}#{line}" : "\n"
    end.join.delete_prefix("\n").chomp
    template_ruby.gsub!("#{indention_spaces}TABLE_VALIDATIONS", table_validations_ruby)
    template_ruby.sub!("\n\n  VALIDATOR_CLASSES", validator_classes_ruby)

    write_schema_validations(template_ruby)
  end

  def write_schema_validations(template_ruby)
    return unless Rails.env.development?

    File.write(Rails.root.join('app/models/concerns/schema_validations.rb'), template_ruby)
  end

  def create_table(table_name, *, &)
    table = GeneratedSchemaValidations::Table.new(table_name, enum_types: @enum_types || {}, &)
    @used_validators = (@used_validators || []) | table.validators
    @table_validations_ruby ||= ''
    @table_validations_ruby += table.to_s
  end

  def create_enum(name, values)
    @enum_types ||= {}
    @enum_types[name.to_s] = values
  end

  def do_nothing(*); end
  alias enable_extension do_nothing
  alias create_schema do_nothing
  alias add_foreign_key do_nothing

  private

  def validator_classes_ruby
    (VALIDATORS & @used_validators.to_a).map do |validator|
      ruby = File.read(File.expand_path("validators/#{validator}_validator.rb", __dir__))
      ruby = ruby.delete_prefix("# frozen_string_literal: true\n\n")
      "\n\n#{ruby.lines.map { |line| line.strip.present? ? "  #{line}" : line }.join.chomp}"
    end.join
  end
end
