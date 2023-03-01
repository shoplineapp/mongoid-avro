require 'spec_helper'

class TestModel
  include Mongoid::Document
  include Mongoid::Avro

  field :name, type: String
  field :age, type: Integer
  field :height, type: Float
end

RSpec.describe Mongoid::Avro do
  describe '.generate_avro_schema' do
    context 'when avro_format option is not given' do
      it 'normalizes the field type to avro format' do
        schema = TestModel.generate_avro_schema(ns: 'ec_core')

        expect(schema.name).to eq(TestModel.name)
        expect(schema.namespace).to eq('ec_core')
        expect(schema.fields_hash['_id'].type.type_sym).to eq(:string)
        expect(schema.fields_hash['name'].type.type_sym).to eq(:string)
        expect(schema.fields_hash['age'].type.type_sym).to eq(:int)
        expect(schema.fields_hash['height'].type.type_sym).to eq(:float)
      end
    end

    context 'when avro_format option is given' do
      class TestModel
        include Mongoid::Document
        include Mongoid::Avro

        field :name, type: String, avro_format: :string
        field :age, type: Integer, avro_format: :int
        field :height, type: Float, avro_format: :double
      end

      it 'normalizes the field type to the given avro format' do
        schema = TestModel.generate_avro_schema

        expect(schema.name).to eq(TestModel.name)
        expect(schema.namespace).to eq('')
        expect(schema.fields_hash['_id'].type.type_sym).to eq(:string)
        expect(schema.fields_hash['name'].type.type_sym).to eq(:string)
        expect(schema.fields_hash['age'].type.type_sym).to eq(:int)
        expect(schema.fields_hash['height'].type.type_sym).to eq(:double)
      end
    end
  end
end
