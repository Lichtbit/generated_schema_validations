# frozen_string_literal: true

RSpec.describe GeneratedSchemaValidations::Table do
  def lines(&)
    described_class.new('users', &).to_s.lines(chomp: true).reject(&:empty?)
  end

  it 'wraps the validations in a method named after the table' do
    expect(lines { nil }).to eq(['def dbv_users_validations(enums: [])', 'end'])
  end

  it 'validates presence of not null columns' do
    expect(lines { |t| t.text 'name', null: false }).to include('  validates_with_filter :name, {presence: {}}')
    expect(lines { |t| t.text 'name' }).not_to include(a_string_including('presence'))
  end

  it 'validates booleans and json without presence' do
    expect(lines do |t|
      t.boolean 'active', null: false
      t.jsonb 'data', null: false
    end).to include(
      '  validates_with_filter :active, {inclusion: {in: [true, false], message: :blank}}',
      '  validates_with_filter :data, {not_null: {}}',
    )
  end

  it 'validates arrays without presence' do
    expect(lines { |t| t.string 'tags', array: true, null: false, limit: 5 }).to eq(
      ['def dbv_users_validations(enums: [])', '  validates_with_filter :tags, {not_null: {}}', 'end'],
    )
  end

  it 'validates the length of limited strings' do
    expect(lines { |t| t.string 'name', limit: 10 }).to include(
      '  validates_with_filter :name, {length: {allow_nil: true, maximum: 10}}',
    )
    expect(lines { |t| t.string 'name' }).not_to include(a_string_including('length'))
  end

  it 'validates the range of integers depending on the limit' do
    output = lines do |t|
      t.integer 'small', limit: 2
      t.integer 'normal'
      t.bigint 'big'
      t.integer 'list', array: true
    end

    expected = [
      'def dbv_users_validations(enums: [])',
      '  validates_with_filter :big, {numericality: {allow_nil: true, only_integer: true, ' \
      'greater_than_or_equal_to: -9223372036854775808, less_than: 9223372036854775808}} ' \
      'unless enums.include?(:big)',
      '  validates_with_filter :normal, {numericality: {allow_nil: true, only_integer: true, ' \
      'greater_than_or_equal_to: -2147483648, less_than: 2147483648}} unless enums.include?(:normal)',
      '  validates_with_filter :small, {numericality: {allow_nil: true, only_integer: true, ' \
      'greater_than_or_equal_to: -32768, less_than: 32768}} unless enums.include?(:small)',
      'end',
    ]
    expect(output).to eq(expected)
  end

  it 'validates the range of decimals and floats' do
    output = lines do |t|
      t.decimal 'price', precision: 5, scale: 2
      t.decimal 'unlimited'
      t.float 'factor'
    end

    expected = [
      'def dbv_users_validations(enums: [])',
      '  validates_with_filter :factor, {numericality: {allow_nil: true}}',
      '  validates_with_filter :price, {numericality: {allow_nil: true, greater_than: -1000, less_than: 1000}}',
      'end',
    ]
    expect(output).to eq(expected)
  end

  it 'validates dates and times to be in the database range' do
    expect(lines do |t|
      t.date 'day'
      t.datetime 'at'
      t.time 'clock'
    end).to include(
      '  validates_with_filter :day, {date_in_db_range: {}}',
      '  validates_with_filter :at, {date_time_in_db_range: {}}',
      '  validates_with_filter :clock, {time_in_db_range: {}}',
    )
  end

  it 'collects not null foreign keys for belongs_to presence' do
    expect(lines do |t|
      t.uuid 'client_id', null: false
      t.bigint 'other_id', null: false
      t.string 'name', null: false
    end).to include('  belongs_to_presence_validations_for([:client_id, :other_id])')
  end

  it 'collects unique indexes' do
    expect(lines do |t|
      t.string 'email'
      t.uuid 'client_id'
      t.string 'slug'
      t.index %w[client_id email], unique: true
      t.index 'slug', unique: true, where: 'slug IS NOT NULL'
      t.index 'email'
      t.index 'lower(email)', unique: true
    end).to include(
      '  bad_uniqueness_validations_for([["slug"]])',
      '  belongs_to_uniqueness_validations_for([["client_id", "email"]])',
      '  uniqueness_validations_for([["client_id", "email"]])',
    )
  end

  it 'ignores statements without validations' do
    expect(lines do |t|
      t.geography 'lonlat', limit: { srid: 4326, type: 'st_point', geographic: true }
      t.virtual 'full_name', type: :string, as: "first || ' ' || last", stored: true
      t.check_constraint 'age > 0', name: 'age_check'
      t.exclusion_constraint 'range WITH &&', using: :gist
      t.unique_constraint ['position'], deferrable: :immediate
    end).to eq(['def dbv_users_validations(enums: [])', 'end'])
  end

  it 'sorts the output independently of the column order' do
    expect(lines do |t|
      t.text 'b', null: false
      t.text 'a', null: false
    end).to eq(lines do |t|
      t.text 'a', null: false
      t.text 'b', null: false
    end)
  end
end
