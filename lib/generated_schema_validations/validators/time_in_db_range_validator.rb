# frozen_string_literal: true

class TimeInDbRangeValidator < ActiveModel::EachValidator
  def validate_each(record, attr_name, value)
    return if value.nil?

    unless value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)
      record.errors.add(attr_name, :invalid)
      return
    end

    # PostgreSQL allows only times in one day
    return if value.to_date == Date.new(2000, 1, 1)

    record.errors.add(attr_name, :invalid)
  end
end
