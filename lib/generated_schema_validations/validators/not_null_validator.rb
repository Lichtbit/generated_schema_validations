# frozen_string_literal: true

# Like presence, but accepts blank values like an empty hash or array
class NotNullValidator < ActiveModel::EachValidator
  def validate_each(record, attr_name, value)
    record.errors.add(attr_name, :blank) if value.nil?
  end
end
