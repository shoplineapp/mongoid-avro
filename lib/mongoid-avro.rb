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
      def generate_avro_schema(namespace:)
        fields = self.fields.inject([]) do |fields, (name, field)|
          # Convert default field type to avro format unless options[:avro_format] is given

          fields << {
            name: name,
            type: field.options[:avro_format] || convert_to_avro_format(type: field.options[:type])
          }
        end

        schema = ::Avro::Schema.parse({
          namespace: namespace,
          type: "record",
          name: to_s,
          fields: fields
        }.to_json)

        Mongoid::Avro.avro_money_schema = nil

        schema
      end

      def convert_to_avro_format(type:)
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
        else
          # If the type is not recognized, raise an error
          # raise ArgumentError, "Unsupported type for avro_format: #{options[:type]}"
          # fallback to string anyway
          "string"
        end
      end
    end
  end
end
