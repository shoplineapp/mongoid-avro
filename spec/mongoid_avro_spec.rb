# frozen_string_literal: true

require "spec_helper"

class TestModel
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Avro

  field :name, type: String
  field :age, type: Integer
  field :height, type: Float
  field :total, type: Money
  field :subtotal, type: Money
end

RSpec.describe Mongoid::Avro do
  describe ".generate_avro_schema" do
    let(:namespace) { "ns1" }
    context "when avro_format option is not given" do
      it "normalizes the field type to default avro format" do
        schema = TestModel.generate_avro_schema(namespace: "ns1").to_avro

        expect(schema["type"]).to eq("record")
        expect(schema["name"]).to eq("TestModel")
        expect(schema["namespace"]).to eq("ns1")
        expect(schema["fields"].detect { |field| field["name"] == "_id" }.fetch("type")).to eq("string")
        expect(schema["fields"].detect { |field| field["name"] == "created_at" }.fetch("type")).to eq(
          {
            "type" => "long",
            "logicalType" => "timestamp-millis"
          }
        )
        expect(schema["fields"].detect { |field| field["name"] == "name" }.fetch("type")).to eq("string")
        expect(schema["fields"].detect { |field| field["name"] == "age" }.fetch("type")).to eq("int")
        expect(schema["fields"].detect { |field| field["name"] == "height" }.fetch("type")).to eq("double")
        expect(schema["fields"].detect { |field| field["name"] == "total" }.fetch("type")).to include(
          {
            "type" => "record",
            "name" => "Money",
            "namespace" => "ns1",
            "fields" => [
              { "name" => "cents", "type" => "int" },
              { "name" => "currency_iso", "type" => "string" }
            ]
          }
        )
        expect(schema["fields"].detect { |field| field["name"] == "subtotal" }.fetch("type")).to eq("ns1.Money")
      end
    end

    context "when avro_format option is given" do
      let(:namespace) { "ns2" }
      class TestModel2
        include Mongoid::Document
        include Mongoid::Timestamps
        include Mongoid::Avro

        field :created_at, type: Time, avro_format: {
          type: "long",
          logicalType: "timestamp-micros"
        }
        field :name, type: String, avro_format: :string
        field :age, type: Integer, avro_format: :long
        field :height, type: Float, avro_format: :float
      end

      it "normalizes the field type to the given avro format" do
        schema = TestModel2.generate_avro_schema(namespace: namespace).to_avro

        expect(schema["type"]).to eq("record")
        expect(schema["name"]).to eq("TestModel2")
        expect(schema["namespace"]).to eq("ns2")
        expect(schema["fields"].detect { |field| field["name"] == "_id" }.fetch("type")).to eq("string")
        expect(schema["fields"].detect { |field| field["name"] == "created_at" }.fetch("type")).to eq(
          {
            "type" => "long",
            "logicalType" => "timestamp-micros"
          }
        )
        expect(schema["fields"].detect { |field| field["name"] == "name" }.fetch("type")).to eq("string")
        expect(schema["fields"].detect { |field| field["name"] == "age" }.fetch("type")).to eq("long")
        expect(schema["fields"].detect { |field| field["name"] == "height" }.fetch("type")).to eq("float")
      end
    end
  end
end
