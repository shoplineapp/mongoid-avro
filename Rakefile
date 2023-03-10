# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: %i[spec]

namespace :mongoid_avro do

  desc "To generate an avro schema with mongoid_avro:generate_schema[model, namesapce]"
  task :generate_schema, [:model, :namespace] do |t, args|
    model_klass = model.to_s.camelize.classify.constantize
    model_klass.include(::Mongoid::Avro)
    puts model_klass.generate_avro_schema(namespace: namespace).to_avro.to_json
  end
end
