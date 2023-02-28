# frozen_string_literal: true

class GeneratedSchemaValidations::Table
  Validation = Struct.new(:attribute, :validator, :options) do
    def to_s
      "validates_with_filter #{attribute.to_sym.inspect}, #{{ validator => options }.inspect}"
    end
  end

  attr_reader :table_name

  def initialize(table_name, &block)
    @table_name = table_name
    @column_names = []
    @possible_belongs_to_not_null_columns = []
    @unique_indexes = []
    @validations = []

    instance_eval(&block)
  end

  def to_s
    string = "\n"
    string += "def dbv_#{table_name}_validations\n"
    if @possible_belongs_to_not_null_columns.present?
      string += "  belongs_to_presence_validations_for(#{@possible_belongs_to_not_null_columns.inspect})\n"
    end
    string += "  belongs_to_uniqueness_validations_for(#{@unique_indexes.inspect})\n" if @unique_indexes.present?
    string += "  uniqueness_validations_for(#{@unique_indexes.inspect})\n" if @unique_indexes.present?
    string += @validations.uniq.map { |v| "  #{v}\n" }.join
    "#{string}end\n"
  end

  def validates(attribute, validator, options = {})
    @validations.push(Validation.new(attribute, validator, options))
  end

  def null_validation(datatype, name, column_options)
    @column_names.push(name.to_s)

    return if column_options[:null] != false

    @possible_belongs_to_not_null_columns.push(name.to_sym) if datatype.in?(%i[bigint integer uuid])
    if datatype == :boolean
      validates name, :inclusion, in: [true, false], message: :blank
    else
      validates name, :presence
    end
  end

  def uuid(name, column_options = {})
    null_validation(:uuid, name, column_options)
  end

  def bigint(name, column_options = {})
    null_validation(:bigint, name, column_options)

    validates name, :numericality, allow_nil: true
  end

  def integer(name, column_options = {})
    null_validation(:integer, name, column_options)

    return if column_options[:array]

    integer_range = ::ActiveRecord::Type::Integer.new.send(:range)
    options = { allow_nil: true, only_integer: true, greater_than_or_equal_to: integer_range.begin }
    if integer_range.exclude_end?
      options[:less_than] = integer_range.end
    else
      options[:less_than_or_equal_to] = integer_range.end
    end

    validates name, :numericality, options
  end

  def datetime(name, column_options = {})
    null_validation(:datetime, name, column_options)
    validates name, :date_time_in_db_range
  end

  def date(name, column_options = {})
    null_validation(:date, name, column_options)
    validates name, :date_in_db_range
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

  def index(names, index_options = {})
    names = [names] unless names.is_a?(Array)
    return unless index_options[:unique]
    return unless names.all? { |name| name.to_s.in?(@column_names) }

    @unique_indexes.push(names.map(&:to_s))
  end
end
