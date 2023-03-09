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
  field :object, type: Hash
  field :updated_at, type: Time, avro_format: {
    type: "long",
    logicalType: "timestamp-micros"
  }
end

def get_field_by_name(fields, name)
  fields.detect { |field| field["name"] == name }
end

RSpec.describe Mongoid::Avro do
  describe ".generate_avro_schema" do
    subject { TestModel.generate_avro_schema(namespace: "ns1", optional: optional).to_avro }

    let(:optional) { false }
    let(:field) { get_field_by_name(subject["fields"], field_name) }
    let(:field_name) { "_id" }

    it "use class name as default schema name" do
      expect(subject["name"]).to eq("TestModel")
      expect(subject["type"]).to eq("record")
    end

    it "use given namespace as namespace" do
      expect(subject["namespace"]).to eq("ns1")
    end

    it "convert object _id to string" do
      expect(field["type"]).to eq("string")
    end

    context "when default type is Time" do
      let(:field_name) { "created_at" }

      it "convert to type: long and logicalType: timestamp-millis" do
        expect(field["type"]).to eq(
          {
            "type" => "long",
            "logicalType" => "timestamp-millis"
          }
        )
      end
    end

    context "when default type if String" do
      let(:field_name) { "name" }

      it "convert to type: string" do
        expect(field["type"]).to eq("string")
      end
    end

    context "when default type is Integer" do
      let(:field_name) { "age" }

      it "convert to type: int" do
        expect(field["type"]).to eq("int")
      end
    end

    context "when default type is Float" do
      let(:field_name) { "height" }

      it "convert to type: double" do
        expect(field["type"]).to eq("double")
      end
    end

    context "when default type is Money" do
      let(:field_name) { "total" }

      it "convert to type: Money record" do
        expect(field["type"]).to include(
          {
            "type" => "record",
            "name" => "Money",
            "namespace" => "ns1",
            "fields" => [
              { "name" => "cents", "type" => "long" },
              { "name" => "currency_iso", "type" => "string" }
            ]
          }
        )
      end
    end

    context "when default type is Hash" do
      let(:field_name) { "object" }

      it "convert to type: string" do
        expect(field["type"]).to eq("string")
      end
    end

    context "when avro_format option is given" do
      it "shows given arvo_format of the field" do
        expect(get_field_by_name(subject["fields"], "nickname")["type"]).to eq("string")
        expect(get_field_by_name(subject["fields"], "balance")["type"]).to eq("long")
        expect(get_field_by_name(subject["fields"], "weight")["type"]).to eq("float")
        expect(get_field_by_name(subject["fields"], "updated_at")["type"]).to eq(
          {
            "type" => "long",
            "logicalType" => "timestamp-micros"
          }
        )
      end
    end

    context "when there exists more than one Money fields" do
      let(:field_name) { "subtotal" }

      it "shows custom type of Money which defined under the namespace" do
        expect(field["type"]).to eq("ns1.Money")
      end
    end

    context "when optional is true" do
      let(:optional) { true }

      it "convert default _id to string" do
        expect(field["type"]).to eq("string")
        expect(field).not_to have_key("default")
      end

      context "when default type is Time" do
        let(:field_name) { "created_at" }

        it "convert to type: long and logicalType: timestamp-millis union with null" do
          expect(field["type"]).to eq(
            [
              "null",
              {
                "type" => "long",
                "logicalType" => "timestamp-millis"
              }
            ]
          )
        end
      end

      context "when default type is String" do
        let(:field_name) { "name" }

        it "convert to type: string union with null" do
          expect(field["type"]).to eq(["null", "string"])
        end
      end

      context "when default type is Integer" do
        let(:field_name) { "age" }

        it "convert to type: int union with null" do
          expect(field["type"]).to eq(["null", "int"])
        end
      end

      context "when default type is Float" do
        let(:field_name) { "height" }

        it "convert to type: double union with null" do
          expect(field["type"]).to eq(["null", "double"])
        end
      end

      context "when default type is Hash" do
        let(:field_name) { "object" }

        it "convert to type: string" do
          expect(field["type"]).to eq(["null", "string"])
        end
      end

      context "when default type is Money" do
        let(:field_name) { "total" }

        it "convert to type: Money record union with null" do
          expect(field["type"]).to eq(
            [
              "null",
              {
                "type" => "record",
                "name" => "Money",
                "namespace" => "ns1",
                "fields" => [
                  { "name" => "cents", "type" => "long" },
                  { "name" => "currency_iso", "type" => "string" }
                ]
              }
            ]
          )
        end
      end

      context "when there exists more than one Money fields" do
        let(:field_name) { "subtotal" }

        it "shows custom type of Money which defined under the namespace union with null" do
          expect(field["type"]).to eq(
            [
              "null",
              "ns1.Money"
            ]
          )
        end
      end
    end
  end
end
