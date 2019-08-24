require "helper"
require "avro_turf/test/fake_confluent_schema_registry_server"
require "fluent/plugin/formatter_avro_turf_messaging"

class AvroTurfFormatterTest < Test::Unit::TestCase
  def registry_url
    "http://schema-registry.example.com:8081/"
  end

  setup do
    Fluent::Test.setup
    stub_request(:any, /^#{registry_url}/).to_rack(FakeConfluentSchemaRegistryServer)
    FakeConfluentSchemaRegistryServer.clear
  end

  def schemas_path
    File.expand_path("../schemas", __dir__)
  end

  def user_record
    {
      "username" => "joker1007",
      "email" => "dummy@example.com",
      "created_at" => Time.utc(2019, 8, 24, 18, 1, 2).to_i * 1000
    }
  end

  def person_record
    {
      "first_name" => "John",
      "last_name" => "Doe",
    }
  end

  test "format" do
    d = create_driver(
      schema_registry_url: registry_url,
      schemas_path: schemas_path,
    )
    formatted = d.instance.format("tag.test", event_time, user_record.merge("schema_name" => "user"))
    avro_turf = AvroTurf::Messaging.new(registry_url: registry_url, schemas_path: schemas_path)
    decoded = avro_turf.decode(formatted, schema_name: "user")
    assert { decoded == user_record }
  end

  test "format with inline schema" do
    schema = {
      "name" => "person",
      "type" => "record",
      "fields" => [
        {
          "name" => "first_name",
          "type" => "string"
        },
        {
          "name" => "last_name",
          "type" => "string"
        },
      ]
    }
    d = create_driver(
      schema_registry_url: registry_url,
      schema: schema
    )
    formatted = nil
    assert_nothing_raised do
      formatted = d.instance.format("tag.test", event_time, person_record)
    end
    assert_not_nil(formatted)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Formatter.new(Fluent::Plugin::AvroTurfFormatter).configure(conf)
  end
end
