# frozen_string_literal: true

# Generates the concern from a real database and uses it in models.
ActiveRecord::Schema.define do
  create_table :clients, force: true do |t|
    t.string :name, null: false, limit: 20
  end

  create_table :users, force: true do |t|
    t.references :client, null: false
    t.string :email, null: false
    t.string :nickname
    t.integer :age
    t.integer :role, null: false, default: 0
    t.boolean :admin, null: false, default: false
    t.json :settings, null: false, default: {}
    t.decimal :balance, precision: 5, scale: 2
    t.date :born_on
    t.datetime :seen_at
    t.time :wakes_at
    t.timestamps
    t.index %i[client_id email], unique: true
    t.index :nickname, unique: true, where: 'nickname IS NOT NULL'
  end
end

POSTGRESQL = ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'

if POSTGRESQL
  ActiveRecord::Schema.define do
    enable_extension 'citext'
    enable_extension 'hstore'
    enable_extension 'ltree'

    drop_table :pg_columns, if_exists: true
    drop_enum :mood, if_exists: true
    create_enum :mood, %w[sad ok happy]

    create_table :pg_columns, force: true do |t|
      t.serial :position, null: false
      t.bigserial :big_position, null: false
      t.oid :file
      t.money :price
      t.timestamptz :seen_at
      t.citext :email, null: false
      t.bit :flag
      t.bit :flags, limit: 4
      t.bit_varying :mask, limit: 8
      t.enum :mood, enum_type: :mood
      t.hstore :settings, null: false, default: {}
      t.ltree :category, null: false, default: ''
      t.tsvector :search
      t.daterange :period
      t.numrange :amounts
      t.tsrange :local_times
      t.tstzrange :times
      t.int4range :ages
      t.int8range :counts
      t.inet :ip
      t.cidr :network
      t.macaddr :mac
      t.interval :duration
      t.point :location
      t.line :horizon
      t.lseg :segment
      t.box :area
      t.path :route
      t.polygon :shape
      t.circle :radius
      t.string :tags, array: true, null: false, default: []
      t.virtual :upper_email, type: :string, as: 'upper(email)', stored: true
      t.check_constraint 'length(email) > 3', name: 'email_length'
      t.exclusion_constraint 'period WITH &&', using: :gist, name: 'period_overlap'
      t.unique_constraint :position, name: 'unique_position'
    end
  end
end

begin
  $stdout = StringIO.new
  GeneratedSchemaValidations::DumpChecker.generate
  GENERATED_SCHEMA_VALIDATIONS = $stdout.string
  eval(GENERATED_SCHEMA_VALIDATIONS, TOPLEVEL_BINDING) # rubocop:disable Security/Eval
ensure
  $stdout = STDOUT
end

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include SchemaValidations
end

class Client < ApplicationRecord
  schema_validations
end

class User < ApplicationRecord
  belongs_to :client
  enum :role, { member: 0, owner: 1 }

  schema_validations exclude: [:nickname]
end

if POSTGRESQL
  class PgColumn < ApplicationRecord
    schema_validations
  end
end

RSpec.describe SchemaValidations do
  let(:client) { Client.create!(name: 'Lichtbit') }
  let(:user) { User.new(client:, email: 'mail@example.com') }

  it 'accepts valid records' do
    expect(user).to be_valid
  end

  it 'validates not null columns' do
    user = User.new(admin: nil, settings: nil)

    expect(user).not_to be_valid
    expect(user.errors.to_hash).to eq(
      client: ["can't be blank"],
      email: ["can't be blank"],
      admin: ["can't be blank"],
      settings: ["can't be blank"],
    )
    expect(user.errors).not_to include(:client_id)
  end

  it 'accepts empty json values' do
    user.settings = []

    expect(user).to be_valid
  end

  it 'validates the length of limited strings' do
    expect(Client.new(name: 'x' * 21)).not_to be_valid
  end

  it 'validates the range of numbers' do
    user.age = 2**31
    user.balance = 1000

    expect(user).not_to be_valid
    expect(user.errors.attribute_names).to contain_exactly(:age, :balance)
  end

  it 'skips the numericality of enums' do
    user.role = :owner

    expect(user).to be_valid
  end

  it 'validates dates in the database range' do
    user.born_on = Date.new(6_000_000)
    user.seen_at = Time.utc(300_000)

    expect(user).not_to be_valid
    expect(user.errors.attribute_names).to contain_exactly(:born_on, :seen_at)
  end

  it 'validates unique indexes' do
    User.create!(client:, email: 'mail@example.com')

    expect(user).not_to be_valid
    expect(user.errors.details).to include(email: [{ error: :taken, value: 'mail@example.com' }])
    expect(User.new(client:, email: 'other@example.com')).to be_valid
  end

  it 'refuses unique indexes with where clause' do
    expect do
      Class.new(ApplicationRecord) do
        self.table_name = 'users'
        schema_validations
      end
    end.to raise_error(/Unique index with where clause/)
  end

  it 'raises if a model misses schema_validations' do
    expect { eval('class MissingCall < ApplicationRecord; end', binding, __FILE__, __LINE__) }
      .to raise_error('MissingCall: schema_validations or skip_schema_validations missing')
  end

  it 'allows to skip schema_validations' do
    expect { eval(<<~RUBY, binding, __FILE__, __LINE__ + 1) }.not_to raise_error
      class SkippedCall < ApplicationRecord
        skip_schema_validations
      end
    RUBY
  end

  it 'does not require schema_validations in abstract classes' do
    expect { eval(<<~RUBY, binding, __FILE__, __LINE__ + 1) }.not_to raise_error
      class AbstractRecord < ApplicationRecord
        self.abstract_class = true
      end
    RUBY
  end

  it 'ignores missing tables in relaxed mode' do
    described_class.relaxed!
    model = Class.new(ApplicationRecord) do
      self.table_name = 'new_models'
      schema_validations
    end

    expect(model.validators).to be_empty
  ensure
    described_class.relaxed = false
  end

  describe 'PostgreSQL columns', if: POSTGRESQL do
    let(:record) { PgColumn.new(email: 'mail@example.com') }

    it 'generates validations for all column types' do
      expect(GENERATED_SCHEMA_VALIDATIONS).to include(<<-'RUBY')
    def dbv_pg_columns_validations(enums: [])
      belongs_to_uniqueness_validations_for([["position"]])
      uniqueness_validations_for([["position"]])
      validates_with_filter :big_position, {numericality: {allow_nil: true, only_integer: true, greater_than_or_equal_to: -9223372036854775808, less_than: 9223372036854775808}} unless enums.include?(:big_position)
      validates_with_filter :category, {not_null: {}}
      validates_with_filter :email, {presence: {}}
      validates_with_filter :file, {numericality: {allow_nil: true, only_integer: true, greater_than_or_equal_to: 0, less_than: 4294967296}}
      validates_with_filter :flag, {format: {allow_nil: true, with: /\A[01]*\z/}}
      validates_with_filter :flag, {length: {allow_nil: true, is: 1}}
      validates_with_filter :flags, {format: {allow_nil: true, with: /\A[01]*\z/}}
      validates_with_filter :flags, {length: {allow_nil: true, is: 4}}
      validates_with_filter :mask, {format: {allow_nil: true, with: /\A[01]*\z/}}
      validates_with_filter :mask, {length: {allow_nil: true, maximum: 8}}
      validates_with_filter :mood, {inclusion: {allow_nil: true, in: ["sad", "ok", "happy"]}} unless enums.include?(:mood)
      validates_with_filter :position, {numericality: {allow_nil: true, only_integer: true, greater_than_or_equal_to: -2147483648, less_than: 2147483648}} unless enums.include?(:position)
      validates_with_filter :price, {numericality: {allow_nil: true, greater_than_or_equal_to: -92233720368547758, less_than_or_equal_to: 92233720368547758}}
      validates_with_filter :seen_at, {date_time_in_db_range: {}}
      validates_with_filter :settings, {not_null: {}}
      validates_with_filter :tags, {not_null: {}}
    end
      RUBY
    end

    it 'saves valid records' do
      record.assign_attributes(
        file: 42, price: 12.5, seen_at: Time.current, flag: '1', flags: '1010', mask: '101', mood: 'ok',
        settings: { 'a' => 'b' }, category: 'top.sub', search: 'fire sport',
        period: Date.new(2025, 1, 1)...Date.new(2025, 2, 1),
        amounts: 1..2, local_times: Time.utc(2025)..Time.utc(2026), times: Time.utc(2025)..Time.utc(2026), ages: 1...10,
        counts: 1...(2**40), ip: '192.168.0.1', network: '10.0.0.0/8', mac: '08:00:2b:01:02:03', duration: 1.hour,
        location: [1, 2], horizon: '{1,2,3}', segment: '[(0,0),(1,1)]', area: '(1,1),(0,0)', route: '((0,0),(1,1))',
        shape: '((0,0),(1,1),(1,0))', radius: '<(0,0),1>', tags: %w[a b]
      )

      expect(record).to be_valid
      expect { record.save! }.not_to raise_error
      expect(record.reload.position).to be_present
    end

    it 'accepts blank values that are valid in the database' do
      expect(record).to be_valid
      expect(record.attributes.values_at('settings', 'category', 'tags')).to eq([{}, '', []])
    end

    it 'validates the not null constraint of columns with blank values' do
      record.assign_attributes(settings: nil, category: nil, tags: nil)

      expect(record).not_to be_valid
      expect(record.errors.attribute_names).to contain_exactly(:settings, :category, :tags)
    end

    it 'validates values the database would refuse' do
      record.assign_attributes(file: -1, price: 10**17, flag: '2', flags: '101', mask: '101010101', mood: 'angry')

      expect(record).not_to be_valid
      expect(record.errors.attribute_names).to contain_exactly(:file, :price, :flag, :flags, :mask, :mood)
    end

    it 'validates unique constraints' do
      PgColumn.create!(email: 'first@example.com', position: 1000)
      record.position = 1000

      expect(record).not_to be_valid
      expect(record.errors.details).to include(position: [{ error: :taken, value: 1000 }])
    end
  end

  describe SchemaValidations::TimeInDbRangeValidator do
    let(:record) do
      Class.new do
        include ActiveModel::Validations

        attr_accessor :at

        validates_with SchemaValidations::TimeInDbRangeValidator, attributes: [:at]
        def self.name = 'Record'
      end.new
    end

    it 'accepts only times of the PostgreSQL day' do
      record.at = Time.utc(2000, 1, 1, 12)
      expect(record).to be_valid

      record.at = Time.utc(2000, 1, 2, 12)
      expect(record).not_to be_valid

      record.at = '12:00'
      expect(record).not_to be_valid
    end
  end
end
