# frozen_string_literal: true

require "spec_helper"

class TestModel
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Avro

  field :name, type: String
  field :nickname, type: String, avro_format: :string
  field :age, type: Integer
  field :balance, type: Integer, avro_format: :long
  field :height, type: Float
  field :weight, type: Float, avro_format: :float
  field :total, type: Money
  field :subtotal, type: Money
  field :updated_at, type: Time, avro_format: {
    type: "long",
    logicalType: "timestamp-micros"
  }
end

RSpec.describe Mongoid::Avro do
  describe ".generate_avro_schema" do
    subject { TestModel.generate_avro_schema(namespace: "ns1").to_avro }

    it "use class name as default schema name" do
      expect(subject["name"]).to eq("TestModel")
      expect(subject["type"]).to eq("record")
    end

    it "use given namespace as namespace" do
      expect(subject["namespace"]).to eq("ns1")
    end

    it "convert default _id to string" do
      expect(subject["fields"].detect { |field| field["name"] == "_id" }.fetch("type")).to eq("string")
    end

    it "convert default timestamp to type: long and logicalType: timestamp-millis" do
      expect(subject["fields"].detect { |field| field["name"] == "created_at" }.fetch("type")).to eq(
        {
          "type" => "long",
          "logicalType" => "timestamp-millis"
        }
      )
    end

    it "convert default string to string" do
      expect(subject["fields"].detect { |field| field["name"] == "name" }.fetch("type")).to eq("string")
    end

    it "convert default Integer to int" do
      expect(subject["fields"].detect { |field| field["name"] == "age" }.fetch("type")).to eq("int")
    end

    it "convert default Float to double" do
      expect(subject["fields"].detect { |field| field["name"] == "height" }.fetch("type")).to eq("double")
    end

    it "shows custom type of Money" do
      expect(subject["fields"].detect { |field| field["name"] == "total" }.fetch("type")).to include(
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
    end

    context "when avro_format option is given" do
      it "shows given arvo_format of the field" do
        expect(subject["fields"].detect { |field| field["name"] == "nickname" }.fetch("type")).to eq("string")
        expect(subject["fields"].detect { |field| field["name"] == "balance" }.fetch("type")).to eq("long")
        expect(subject["fields"].detect { |field| field["name"] == "weight" }.fetch("type")).to eq("float")
        expect(subject["fields"].detect { |field| field["name"] == "updated_at" }.fetch("type")).to eq(
          {
            "type" => "long",
            "logicalType" => "timestamp-micros"
          }
        )
      end
    end

    context "when there exists more than one Money fields" do
      it "shows custom type of Money which defined under the namespace" do
        expect(subject["fields"].detect { |field| field["name"] == "subtotal" }.fetch("type")).to eq("ns1.Money")
      end
    end
  end
end
