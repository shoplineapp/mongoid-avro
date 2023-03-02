require 'avro'

Mongoid::Fields.option :avro_format do |model, field, value|
end

module Mongoid
  module Avro
    extend ActiveSupport::Concern

    included do
      cattr_accessor :avro_schema
    end

    module ClassMethods
      def field(name, options = {})
        if options[:avro_format].nil?
          # If avro_format is not given, normalize the type to an avro type
          options[:avro_format] = case options[:type].to_s
                                  when 'String', 'Symbol' then 'string'
                                  when 'Integer' then 'int'
                                  when 'Float' then 'float'
                                  when 'BigDecimal' then 'decimal'
                                  when 'Boolean' then 'boolean'
                                  when 'DateTime', 'Time'
                                    {
                                      type: 'long',
                                      logicalType: 'timestamp-millis'
                                    }
                                  when 'Date'
                                    {
                                      type: 'int',
                                      logicalType: 'date'
                                    }
                                  when 'BSON::ObjectId' then 'string'
                                  else
                                    # If the type is not recognized, raise an error
                                    # raise ArgumentError, "Unsupported type for avro_format: #{options[:type]}"
                                    # fallback to string anyway
                                    'string'
                                  end
        end

        super(name, options)
      end

      def generate_avro_schema(ns: nil)
        fields = self.fields.inject([]) do |fields, (name, field)|
          fields << {
            name: name,
            type: field.options[:avro_format] || 'string'
          }
        end

        ::Avro::Schema.parse({
          namespace: ns.to_s,
          type: 'record',
          name: self.to_s,
          fields: fields
        }.to_json)
      end
    end
  end
end
