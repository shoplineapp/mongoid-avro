require 'avro'

Mongoid::Fields.option :avro_format do |model, field, value|
end

module Mongoid
  module Avro
    extend ActiveSupport::Concern
    cattr_accessor :avro_namespace
    cattr_accessor :avro_money_schema

    MONEY_AVRO_SCHEMA = {
      type: 'record',
      name: 'Money',
      fields: [
        { name: 'cents', type: 'int' },
        { name: 'currency_iso', type: 'string' }
      ]
    }

    module ClassMethods
      def field(name, options = {})
        if options[:avro_format].nil?
          # If avro_format is not given, normalize the type to an avro type
          options[:avro_format] = case options[:type].to_s
                                  when 'String', 'Symbol' then 'string'
                                  when 'Integer' then 'int'
                                  when 'Float' then 'double'
                                  when 'BigDecimal' then 'decimal'
                                  when 'Boolean', 'Mongoid::Boolean' then 'boolean'
                                  when 'Money' #then 'string'
                                    if ::Mongoid::Avro.avro_money_schema.present?
                                      'Money'
                                    else
                                      ::Mongoid::Avro.avro_money_schema = ::Mongoid::Avro::MONEY_AVRO_SCHEMA
                                    end
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

      def generate_avro_schema
        fields = self.fields.inject([]) do |fields, (name, field)|
          fields << {
            name: name,
            type: field.options[:avro_format] || 'string'
          }
        end

        schema = ::Avro::Schema.parse({
          namespace: ::Mongoid::Avro.avro_namespace.to_s,
          type: 'record',
          name: self.to_s,
          fields: fields
        }.to_json)

        Mongoid::Avro.avro_money_schema = nil

        schema
      end
    end
  end
end
