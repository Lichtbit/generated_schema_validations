# frozen_string_literal: true

class GeneratedSchemaValidations::Dumper
  def self.generate
    return unless Rails.env.development?

    file = Tempfile.new(['schema', '.rb'])
    begin
      schema_content = File.read(Rails.root.join('db/schema.rb'))
      schema_content.gsub!('ActiveRecord::Schema', 'GeneratedSchemaValidations::Dumper')
      raise 'The scheme is not well-formed.' if schema_content.include?('ActiveRecord')

      file.write(schema_content)
      file.close

      load file.path
    ensure
      file.unlink
    end
  end

  def self.define(info = {}, &block)
    new.define(info, &block)
  end

  def define(info, &block)
    instance_eval(&block)

    template_ruby = File.read(File.expand_path('template.rb', File.dirname(__FILE__)))
    template_ruby.gsub!('VERSION_INFO', info[:version].to_s)
    indention_spaces = template_ruby.match(/( +)TABLE_VALIDATIONS/)[1]
    table_validations_ruby = @table_validations_ruby.lines.map do |line|
      line.strip.present? ? "#{indention_spaces}#{line}" : "\n"
    end.join
    template_ruby.gsub!("#{indention_spaces}TABLE_VALIDATIONS", table_validations_ruby)

    File.write(Rails.root.join('app/models/concerns/schema_validations.rb'), template_ruby)
  end

  def create_table(table_name, *, &block)
    @table_validations_ruby ||= ''
    @table_validations_ruby += GeneratedSchemaValidations::Table.new(table_name, &block).to_s
  end

  def do_nothing(*); end
  alias enable_extension do_nothing
  alias add_foreign_key do_nothing
end
