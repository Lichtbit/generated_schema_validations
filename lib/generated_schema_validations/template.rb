# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.

# generated from version VERSION_INFO

module SchemaValidations
  extend ActiveSupport::Concern

  included do
    class_attribute :schema_validations_excluded_columns, default: %i[id created_at updated_at type]
  end

  class_methods do
    def schema_validations(exclude: [], schema_table_name: table_name)
      self.schema_validations_excluded_columns += exclude
      send("dbv_#{schema_table_name}_validations")
    end

    TABLE_VALIDATIONS

    def validates_with_filter(attribute, options)
      return if attribute.to_sym.in?(schema_validations_excluded_columns)

      validates attribute, options
    end

    def belongs_to_presence_validations_for(not_null_columns)
      reflect_on_all_associations(:belongs_to).each do |association|
        if not_null_columns.include?(association.foreign_key.to_sym)
          validates association.name, presence: true
          schema_validations_excluded_columns.push(association.foreign_key.to_sym)
        end
      end
    end

    def belongs_to_uniqueness_validations_for(unique_indexes)
      reflect_on_all_associations(:belongs_to).each do |association|
        dbv_uniqueness_validations_for(unique_indexes, foreign_key: association.foreign_key.to_s,
                                                       column: association.name)
      end
    end

    def uniqueness_validations_for(unique_indexes)
      unique_indexes.each do |names|
        names.each do |name|
          dbv_uniqueness_validations_for(unique_indexes, foreign_key: name, column: name)
        end
      end
    end

    def dbv_uniqueness_validations_for(unique_indexes, foreign_key:, column:)
      unique_indexes.each do |names|
        next unless foreign_key.in?(names)
        next if column.to_sym.in?(schema_validations_excluded_columns)

        scope = (names - [foreign_key]).map(&:to_sym)
        options = { allow_nil: true }
        options[:scope] = scope if scope.any?
        options[:if] = (proc do |record|
          if scope.all? { |scope_sym| record.public_send(:"#{scope_sym}?") }
            record.public_send(:"#{foreign_key}_changed?")
          else
            false
          end
        end)

        validates column, uniqueness: options
      end
    end
  end
end
