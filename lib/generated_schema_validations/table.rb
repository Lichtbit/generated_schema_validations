# frozen_string_literal: true

class GeneratedSchemaValidations::Table
  # Hash#inspect changed with Ruby 3.4. Use its new style on all versions to get the same file everywhere.
  def self.inspect_value(value)
    return value.inspect unless value.is_a?(Hash)

    "{#{value.map { |key, v| "#{key}: #{inspect_value(v)}" }.join(', ')}}"
  end

  Validation = Struct.new(:attribute, :validator, :options) do
    def to_s
      "validates_with_filter #{attribute.to_sym.inspect}, " \
        "#{GeneratedSchemaValidations::Table.inspect_value(validator => options)}"
    end
  end

  ValidationWithoutEnum = Struct.new(:attribute, :validator, :options) do
    def to_s
      "#{Validation.new(attribute, validator, options)} unless enums.include?(#{attribute.to_sym.inspect})"
    end
  end

  # Valid values of these types can be blank, e.g. an empty hash or an empty bit string.
  BLANK_VALUE_TYPES = %i[json jsonb hstore bit_varying ltree tsvector].freeze

  attr_reader :table_name

  def initialize(table_name, enum_types: {}, &)
    @table_name = table_name
    @enum_types = enum_types
    @column_names = []
    @possible_belongs_to_not_null_columns = []
    @bad_indexes = []
    @unique_indexes = []
    @validations = []

    instance_eval(&)
  end

  def to_s
    # sort everything
    @possible_belongs_to_not_null_columns.sort!
    @bad_indexes.sort!
    @unique_indexes.sort!
    @validations.sort_by!(&:to_s)

    string = "\n"
    string += "def dbv_#{table_name}_validations(enums: [])\n"
    if @possible_belongs_to_not_null_columns.present?
      string += "  belongs_to_presence_validations_for(#{@possible_belongs_to_not_null_columns.inspect})\n"
    end
    string += "  bad_uniqueness_validations_for(#{@bad_indexes.inspect})\n" if @bad_indexes.present?
    string += "  belongs_to_uniqueness_validations_for(#{@unique_indexes.inspect})\n" if @unique_indexes.present?
    string += "  uniqueness_validations_for(#{@unique_indexes.inspect})\n" if @unique_indexes.present?
    string += @validations.uniq.map { |v| "  #{v}\n" }.join
    "#{string}end\n"
  end

  def validators
    @validations.map(&:validator).uniq
  end

  def validates(attribute, validator, options = {})
    @validations.push(Validation.new(attribute, validator, options))
  end

  def validates_without_enum(attribute, validator, options = {})
    @validations.push(ValidationWithoutEnum.new(attribute, validator, options))
  end

  def null_validation(datatype, name, column_options)
    @column_names.push(name.to_s)

    return if column_options[:null] != false

    @possible_belongs_to_not_null_columns.push(name.to_sym) if datatype.in?(%i[bigint integer uuid])
    if datatype == :boolean
      validates name, :inclusion, in: [true, false], message: :blank
    elsif datatype.in?(BLANK_VALUE_TYPES) || column_options[:array]
      validates name, :not_null
    else
      validates name, :presence
    end
  end

  def uuid(name, column_options = {})
    null_validation(:uuid, name, column_options)
  end

  def bigint(name, column_options = {})
    null_validation(:bigint, name, column_options)
    integer_range_validation(name, column_options, default_limit: 8)
  end

  def integer(name, column_options = {})
    null_validation(:integer, name, column_options)
    integer_range_validation(name, column_options, default_limit: ::ActiveRecord::Type::Integer::DEFAULT_LIMIT)
  end

  def serial(name, column_options = {})
    # The database sets the value on insert, so it is nil before.
    null_validation(:serial, name, column_options.except(:null))
    integer_range_validation(name, column_options, default_limit: 4)
  end

  def bigserial(name, column_options = {})
    null_validation(:bigserial, name, column_options.except(:null))
    integer_range_validation(name, column_options, default_limit: 8)
  end

  def oid(name, column_options = {})
    null_validation(:oid, name, column_options)
    return if column_options[:array]

    validates name, :numericality, allow_nil: true, only_integer: true,
                                   greater_than_or_equal_to: 0, less_than: 1 << 32
  end

  def money(name, column_options = {})
    null_validation(:money, name, column_options)
    return if column_options[:array]

    # PostgreSQL stores money as 64 bit integer of the smallest currency unit
    limit = (1 << 63) / (10**(column_options[:scale] || 2))
    validates name, :numericality, allow_nil: true, greater_than_or_equal_to: -limit, less_than_or_equal_to: limit
  end

  def datetime(name, column_options = {})
    null_validation(:datetime, name, column_options)
    validates name, :date_time_in_db_range
  end
  alias timestamp datetime
  alias timestamptz datetime

  def date(name, column_options = {})
    null_validation(:date, name, column_options)
    validates name, :date_in_db_range
  end

  def time(name, column_options = {})
    null_validation(:time, name, column_options)
    validates name, :time_in_db_range
  end

  def boolean(name, column_options = {})
    null_validation(:boolean, name, column_options)
  end

  def binary(name, column_options = {})
    null_validation(:binary, name, column_options)
  end

  def string(name, column_options = {})
    text(name, column_options)
  end

  def json(name, column_options = {})
    null_validation(:json, name, column_options)
  end

  def jsonb(name, column_options = {})
    null_validation(:jsonb, name, column_options)
  end

  def xml(name, column_options = {})
    null_validation(:xml, name, column_options)
  end

  def decimal(name, column_options = {})
    null_validation(:decimal, name, column_options)
    return if column_options[:array]
    return if column_options[:precision].blank? || column_options[:scale].blank?

    limit = 10**(column_options[:precision] - (column_options[:scale] || 0))
    validates name, :numericality, allow_nil: true, greater_than: -limit, less_than: limit
  end

  def float(name, column_options = {})
    null_validation(:float, name, column_options)
    return if column_options[:array]

    validates name, :numericality, allow_nil: true
  end

  def text(name, column_options = {})
    null_validation(:text, name, column_options)
    return if column_options[:array]
    return if column_options[:limit].blank?

    validates name, :length, allow_nil: true, maximum: column_options[:limit]
  end
  alias citext text

  def bit(name, column_options = {})
    null_validation(:bit, name, column_options)
    return if column_options[:array]

    validates name, :format, allow_nil: true, with: /\A[01]*\z/
    validates name, :length, allow_nil: true, is: column_options[:limit] || 1
  end

  def bit_varying(name, column_options = {})
    null_validation(:bit_varying, name, column_options)
    return if column_options[:array]

    validates name, :format, allow_nil: true, with: /\A[01]*\z/
    validates name, :length, allow_nil: true, maximum: column_options[:limit] if column_options[:limit]
  end

  def enum(name, column_options = {})
    null_validation(:enum, name, column_options)
    return if column_options[:array]

    values = @enum_types[column_options[:enum_type].to_s]
    validates_without_enum name, :inclusion, allow_nil: true, in: values if values
  end

  # Columns without own validations. The database checks the format, the not null constraint is validated.
  %i[
    daterange numrange tsrange tstzrange int4range int8range
    hstore inet cidr macaddr ltree tsvector interval
    point line lseg box path polygon circle
  ].each do |datatype|
    define_method(datatype) do |name, column_options = {}|
      null_validation(datatype, name, column_options)
    end
  end

  def index(names, index_options = {})
    names = [names] unless names.is_a?(Array)
    return unless index_options[:unique]
    return unless names.all? { |name| name.to_s.in?(@column_names) }

    if index_options[:where]
      @bad_indexes.push(names.map(&:to_s))
    else
      @unique_indexes.push(names.map(&:to_s))
    end
  end

  def unique_constraint(names, _constraint_options = {})
    index(names, unique: true)
  end

  def geography(*)
    # do nothing
  end

  def do_nothing(*); end
  alias virtual do_nothing # generated columns can not be written
  alias check_constraint do_nothing
  alias exclusion_constraint do_nothing

  private

  def integer_range_validation(name, column_options, default_limit:)
    return if column_options[:array]

    # Same bounds as ActiveModel::Type::Integer (min...max), computed here because
    # Rails 8.1 removed the private #range method this used to call.
    max_value = 1 << (((column_options[:limit] || default_limit) * 8) - 1)
    options = { allow_nil: true, only_integer: true, greater_than_or_equal_to: -max_value, less_than: max_value }

    validates_without_enum name, :numericality, options
  end
end
