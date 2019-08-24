# fluent-plugin-avro_turf

[Fluentd](https://fluentd.org/) formatter plugin to format by confluent schema registry format.

see. https://docs.confluent.io/current/schema-registry/serializer-formatter.html

The format is based on Apache Avro, but it is not compatible.

Representative use is formatter for https://github.com/fluent/fluent-plugin-kafka

## Installation

### RubyGems

```
$ gem install fluent-plugin-avro_turf
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-avro_turf"
```

And then execute:

```
$ bundle
```

## Configuration

Example.

```
<format>
  @type avro_turf_messaging

  schema_registry_url http://my-registry:8081/
  schemas_path ./schemas
  schema_name_key schema_name
  default_namespace io.github.joker1007

  exclude_schema_name_key true
</format>
```

| param                      | type   | required | default            | description                                                                                                 |
| -------------------        | ------ | -------- | -------            | --------------------------------------------------------------                                              |
| schema_registry_url        | string | true     |                    | Schema Registry URL parameter (ex: `http://my-registry:8081/`)                                              |
| schemas_path               | string |          | nil                | Schemas path to find avsc from local storage                                                                |
| default_schema_name        | string |          | nil                | Default schema name when the record doesn't have schema_name_key                                            |
| schema_name_key            | string |          | `"schema_name"`    | Field for schema name                                                                                       |
| schema                     | hash   |          | nil                | Inline schema definition. If this parameter is set, `default_schema_name` and `schema_name_key` are ignored |
| default_namespace          | string |          | nil                | Default schema namespace                                                                                    |
| namespace_key              | string |          | `"namespace"`      | Field for namespace                                                                                         |
| schema_version_key         | string |          | `"schema_version"` | Field for schema version                                                                                    |
| exclude_schema_name_key    | bool   |          | false              | Set true to remove schema_name_key field from data                                                          |
| exclude_namespace_key      | bool   |          | false              | Set true to remove namespace_key field from data                                                            |
| exclude_schema_version_key | bool   |          | false              | Set true to remove schema_version_key field from data                                                       |


## Copyright

* Copyright(c) 2019- joker1007
* License
  * Apache License, Version 2.0
