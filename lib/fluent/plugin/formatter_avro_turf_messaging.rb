#
# Copyright 2019- joker1007
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/formatter"
require "avro_turf"
require "avro_turf/messaging"

module Fluent
  module Plugin
    class AvroTurfFormatter < Fluent::Plugin::Formatter
      class AvroTurfVersionImcompatible < StandardError; end

      Fluent::Plugin.register_formatter("avro_turf_messaging", self)

      config_param :schema_registry_url, :string, desc: "Schema Registry URL parameter (ex: `http://my-registry:8081/`)"
      config_param :schemas_path, :string, default: nil, desc: "Schemas path to find avsc from local storage"

      config_param :default_schema_name, :string, default: nil, desc: "Default schema name when the record doesn't have schema_name_key"
      config_param :schema_name_key, :string, default: "schema_name", desc: "Field for schema name"

      config_param :subject, :string, default: nil, desc: "Set Subject explicitly"
      config_param :subject_key, :string, default: nil, desc: "Field for subject (that is override the value that is set by `subject`)"

      config_param :schema, :hash, default: nil, desc: "Inline schema definition. If this parameter is set, `default_schema_name` and `schema_name_key` are ignored"


      config_param :default_namespace, :string, default: nil, desc: "Default schema namespace"
      config_param :namespace_key, :string, default: "namespace", desc: "Field for namespace"

      config_param :schema_version, :string, default: nil, desc: "Set schema_version explicitly"
      config_param :schema_version_key, :string, default: nil, desc: "Field for schema version (that is override the value that is set by `schema_version`)"

      config_param :exclude_schema_name_key, :bool, default: false, desc: "Set true to remove schema_name_key field from data"
      config_param :exclude_namespace_key, :bool, default: false, desc: "Set true to remove namespace_key field from data"
      config_param :exclude_schema_version_key, :bool, default: false, desc: "Set true to remove schema_version_key field from data"
      config_param :exclude_subject_key, :bool, default: false, desc: "Set true to remove subject_key field from data"

      def configure(conf)
        super

        raise Fluent::ConfigError, "Do not set `schema` and `subject` at the same time" if @schema && @subject

        @avro_turf = AvroTurf::Messaging.new(registry_url: @schema_registry_url, schemas_path: @schemas_path)
        if @schema
          schema_store = @avro_turf.instance_variable_get("@schema_store")
          raise AvroTurfVersionImcompatible.new("Cannot access @schema_store") unless schema_store
          schemas = schema_store.instance_variable_get("@schemas")
          raise AvroTurfVersionImcompatible.new("Cannot access @schemas in @schema_store") unless schemas
          Avro::Schema.real_parse(@schema, schemas)
        end

        if @subject && @schema_version.nil?
          # use latest version when fluentd is launced
          @schema_version = @avro_turf.instance_variable_get("@registry").subject_versions(@subject).last

        end
      end

      def format(tag, time, record)
        if @schema
          schema_name = @schema["name"]
          namespace = @schema["namespace"]
        end

        if @schema_name_key
          schema_name ||= @exclude_schema_name_key ? record.delete(@schema_name_key) : record[@schema_name_key]
        end
        schema_name ||= @default_schema_name

        if @namespace_key
          namespace ||= @exclude_namespace_key ? record.delete(@namespace_key) : record[@namespace_key]
        end
        namespace ||= @default_namespace

        if @subject_key
          subject = @exclude_subject_key ? record.delete(@subject_key) : record[@subject_key]
        end
        subject ||= @subject

        if @schema_version_key
          schema_version = @exclude_schema_version_key ? record.delete(@schema_version_key) : record[@schema_version_key]
        end
        schema_version ||= @schema_version

        @avro_turf.encode(record, schema_name: schema_name, namespace: namespace, subject: subject, version: schema_version)
      end
    end
  end
end
