# frozen_string_literal: true

class DateInDbRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attr_name, value)
    return if value.nil?
    return unless value.is_a?(Date)
    return if value.year.between?(-4711, 5_874_896) # see https://www.postgresql.org/docs/9.3/datatype-datetime.html

    record.errors.add(attr_name, :invalid)
  end
end
