# Mongoid::Avro

`mongoid-avro` is a Ruby gem that allows you to convert a `Mongoid` Model schema to an Avro schema. This can be useful if you want to use Avro serialization with your Mongoid data.

---

## Installation

Add mongoid-avro to your Gemfile:
```ruby
gem 'mongoid-avro'
```

And then execute:

```ruby
bundle install
```
---

## Usage

1. Include Mongoid::Avro in your Mongoid model:
```ruby
class MyModel
  include Mongoid::Document
  include Mongoid::Avro
  # ...
end
```
2. Optionally, specify the Avro format for each field using the avro_format option:

```ruby
class MyModel
  include Mongoid::Document
  include Mongoid::Avro

  field :my_field, type: String, avro_format: 'my_custom_format'
  field :my_field_2, type: String, avro_format: {
      type: 'record',
      name: 'Money',
      fields: [
        { name: 'cents', type: 'int' },
        { name: 'currency_iso', type: 'string' }
      ]
    }
  # ...
end
```
The avro_format option can be a string, symbol, or hash.

3. To generate the Avro schema for your model, call generate_avro_schema:

```ruby
schema = MyModel.generate_avro_schema(namespace: 'my.namespace')
```

You can pass an optional namespace parameter to specify the namespace for the Avro schema.

The method returns an `Avro::Schema`.

4. (Optional) Generate avro schema to json
```ruby
schema.to_avro.to_json
```
---
## Field type transform login
### Primitive Types

|Mongoid|Avro|
|-------|----|
|_id field|string|
|Integer|int|
|Float|double|
|String|string|
|Symbol|string|
|Boolean|boolean|
|BSON::ObjectId|string|

### Complext Types
#### DateTime, Time
```json
{ "type": "long", "logicalType": "timestamp-millis"}
```
#### Date
```json
{ "type": "int", "logicalType": "Date"}
```
#### Money
```json
{
  "type": "record",
  "name": "Money",
  "fields": [
    {
      "name": "cents",
      "type": "long"
    },
    {
      "name": "currency_iso",
      "type": "string"
    }
  ]
}
```
#### Array: `Array of strings`
```json
{
  "type": "array",
  "items": "string",
  "default": []
}
```
#### Hash: `string`
- expected to be serialized as json string

### Embedded document
#### Embeds One
```json
{
  "name": "unique_address",
  "type": [
    "null",
    {
      "type": "record",
      "name": "unique_address",
      "namespace": "ns1",
      "fields": [
        {
          "name": "_id",
          "type": "string"
        },
        {
          "name": "address",
          "type": "string"
        },
        {
          "name": "number",
          "type": "int"
        }
      ]
    }
  ]
}
```
#### Embeds Many
```json
{
  "name": "multiple_address",
  "type": [
    "null",
    {
      "type": "array",
      "items": {
        "type": "record",
        "name": "multiple_address",
        "namespace": "ns1",
        "fields": [
          {
            "name": "_id",
            "type": "string"
          },
          {
            "name": "address",
            "type": "string"
          },
          {
            "name": "number",
            "type": "int"
          }
        ]
      }
    }
  ]
}
```
### Associations
#### BelongsTo: `string` as forigen key
#### HasAndBelongsToMany: same as an `Array`
```json
{
  "type": "array",
  "items": "string",
  "default": []
}
```

---

## Validation

```ruby
require 'mongoid-avro'

MyModel.include(Mongoid::Avro)
schema = MyModel.generate_avro_schema(namespace: 'my.namespace')
model = MyModel.find('id')
test_data = JSON.parse(model.attributes.to_json)
Avro::SchemaValidator.validate!(schema, data)
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shoplineapp/mongoid-avro.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
