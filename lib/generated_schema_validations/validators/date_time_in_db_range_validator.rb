# frozen_string_literal: true

class DateTimeInDbRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attr_name, value)
    return if value.nil?
    return unless value.is_a?(DateTime) || value.is_a?(Time)
    return if value.year.between?(-4711, 294_275) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

    record.errors.add(attr_name, :invalid)
  end
end
