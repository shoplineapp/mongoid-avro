# frozen_string_literal: true

require "avro"

Mongoid::Fields.option :avro_format do |model, field, value|
end

module Mongoid
  module Avro
    extend ActiveSupport::Concern

    cattr_accessor :avro_money_schema

    MONEY_AVRO_SCHEMA = {
      type: "record",
      name: "Money",
      fields: [
        { name: "cents", type: "int" },
        { name: "currency_iso", type: "string" }
      ]
    }.freeze

    module ClassMethods
      def generate_avro_schema(namespace:, optional: true)
        fields = convert_to_fields(self, optional: optional)
        # Handle embedded documents
        relations
          .select { |_field, relation| relation.instance_of?(::Mongoid::Association::Embedded::EmbedsMany) }
          .each do |_field, relation|
          klass = relation.options.fetch(:class_name, relation.name.to_s.camelize).classify.constantize
          _fields = convert_to_fields(klass, optional: optional)

          fields << {
            name: relation.name,
            type: {
              type: "array",
              name: relation.name,
              items: {
                type: "record",
                name: relation.name,
                fields: _fields
              }
            }
          }
        end

        # Handle embedded document
        relations
          .select { |_field, relation| relation.instance_of?(::Mongoid::Association::Embedded::EmbedsOne) }
          .each do |_field, relation|
          klass = relation.options.fetch(:class_name, relation.name.to_s.camelize).classify.constantize
          _fields = convert_to_fields(klass, optional: optional)

          fields << {
            name: relation.name,
            type: {
              type: "record",
              name: relation.name,
              fields: _fields
            }
          }
        end

        schema = ::Avro::Schema.parse({
          namespace: namespace,
          type: "record",
          name: to_s,
          fields: fields
        }.to_json)

        schema
      ensure
        Mongoid::Avro.avro_money_schema = nil
      end

      def convert_to_fields(klass, optional:)
        # Convert default field type to avro format unless options[:avro_format] is given
        klass.fields.inject([]) do |fields, (name, field)|
          # explicitly assigns avro_format
          type = field.options[:avro_format]
          # special case: belongs_to; has_and_belongs_to_many will be an array of strings
          type = 'string' if field.options[:association].class == Mongoid::Association::Referenced::BelongsTo
          # implicitly transforms default types
          type ||= convert_to_avro_format(type: field.options[:type])
          # If optional, union with null
          type = ["null", type] if optional && name != '_id'
          fields << {
            name: name,
            type: type
          }.tap { |f| f[:default] = nil if field.options[:avro_format].nil? && optional && name != '_id' }
        end
      end

      def convert_to_avro_format(type: , optional: true)
        case type.to_s
        when "String", "Symbol" then "string"
        when "Integer" then "int"
        when "Float" then "double"
        when "BigDecimal" then "decimal"
        when "Boolean", "Mongoid::Boolean" then "boolean"
        when "Money"
          # The named record in avro is unique.
          if ::Mongoid::Avro.avro_money_schema.present?
            "Money"
          else
            ::Mongoid::Avro.avro_money_schema = ::Mongoid::Avro::MONEY_AVRO_SCHEMA
          end
        when "DateTime", "Time"
          {
            type: "long",
            logicalType: "timestamp-millis"
          }
        when "Date"
          {
            type: "int",
            logicalType: "date"
          }
        when "BSON::ObjectId" then "string"
        when "Array"
          {
            type: "array",
            items: "string",
            default: []
          }
        when "Hash"
          # Expect to encode unstructed data to json string
          "string"
        else
          # If the type is not recognized, raise an error
          raise ArgumentError, "Unsupported type for avro_format: #{type}"
        end
      end
    end
  end
end
