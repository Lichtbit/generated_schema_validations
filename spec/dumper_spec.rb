# frozen_string_literal: true

RSpec.describe GeneratedSchemaValidations::Dumper do
  # The schema is loaded as Ruby file and calls the dumper by its name.
  let(:dumper) do
    stub_const('TestDumper', Class.new(described_class) do
      class << self
        attr_accessor :schema, :output
      end

      def self.read_schema_content = schema
      def write_schema_validations(template_ruby) = (self.class.output = template_ruby)
    end)
  end

  it 'generates the concern from schema.rb' do
    dumper.schema = <<~RUBY
      ActiveRecord::Schema[8.1].define(version: 2025_01_02_030405) do
        enable_extension "pg_catalog.plpgsql"

        create_table "users", force: :cascade do |t|
          t.string "name", limit: 50, null: false
        end

        add_foreign_key "users", "clients"
      end
    RUBY
    dumper.generate

    expect(dumper.output).to include('# generated from version 20250102030405')
    expect(dumper.output).to include(<<-RUBY)
    def dbv_users_validations(enums: [])
      validates_with_filter :name, {length: {allow_nil: true, maximum: 50}}
      validates_with_filter :name, {presence: {}}
    end

    def validates_with_filter(attribute, options)
    RUBY
    expect(dumper.output).not_to include('TABLE_VALIDATIONS')
  end

  it 'adds only the used validator classes' do
    dumper.schema = <<~RUBY
      ActiveRecord::Schema[8.1].define(version: 0) do
        create_table "events" do |t|
          t.date "day"
          t.jsonb "data", null: false
        end
      end
    RUBY
    dumper.generate

    expect(dumper.output.scan(/class (\w+Validator)/).flatten).to eq(%w[DateInDbRangeValidator NotNullValidator])
    expect(dumper.output).to end_with(<<~RUBY)
        class NotNullValidator < ActiveModel::EachValidator
          def validate_each(record, attr_name, value)
            record.errors.add(attr_name, :blank) if value.nil?
          end
        end
      end
    RUBY
    expect { RubyVM::InstructionSequence.compile(dumper.output) }.not_to raise_error
  end

  it 'adds no validator classes if no table uses them' do
    dumper.schema = <<~RUBY
      ActiveRecord::Schema[8.1].define(version: 0) do
        create_table "users" do |t|
          t.string "name", null: false
        end
      end
    RUBY
    dumper.generate

    expect(dumper.output).not_to include('Validator')
    expect(dumper.output).to end_with("    end\n  end\nend\n")
    expect { RubyVM::InstructionSequence.compile(dumper.output) }.not_to raise_error
  end

  it 'generates the concern for a schema without tables' do
    dumper.schema = "ActiveRecord::Schema[8.1].define(version: 0) do\nend\n"
    dumper.generate

    expect(dumper.output).to include('module SchemaValidations')
  end

  it 'refuses a schema with unexpected content' do
    dumper.schema = "ActiveRecord::Schema.define(version: 0) do\n  ActiveRecord::Base\nend\n"

    expect { dumper.generate }.to raise_error('The schema is not well-formed.')
  end

  it 'writes the concern only in development' do
    allow(File).to receive(:write)
    described_class.new.write_schema_validations('content')
    expect(File).not_to have_received(:write)
  end
end
