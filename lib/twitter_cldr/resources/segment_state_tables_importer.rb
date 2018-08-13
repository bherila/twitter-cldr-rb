# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

require 'cldr/export'
require 'json'
require 'yaml'

module TwitterCldr
  module Resources
    class SegmentStateTablesImporter < Importer

      BOUNDARY_TYPES = %w(sentence word)

      # these are the only locales ULI supports at the moment
      EXCEPTIONS_LOCALES = [
        :de, :el, :en, :es, :fi, :fr, :it, :ja, :pt, :ru, :zh, :'zh-Hant'
      ]

      requirement :cldr, Versions.cldr_version
      output_path 'segmentation/state_tables'
      ruby_engine :mri

      def execute
        builder = Segmentation::RuleSetBuilder.new(segments_root)

        write_root_state_tables(builder)
        write_exception_state_tables(builder)
      end

      def write_root_state_tables(builder)
        BOUNDARY_TYPES.each do |boundary_type|
          rule_set = builder.build(boundary_type)
          # binding.pry
          puts 'writing'

          File.write(
            root_output_path_for(boundary_type),
            YAML.dump(rule_set)
          )

          puts 'done'
        end
      end

      def write_exception_state_tables(builder)
        EXCEPTIONS_LOCALES.each do |locale|
          exceptions = exceptions_for(locale)
          next if exceptions.empty?
          exception_rule = builder.exception_rule_for(exceptions)

          File.write(
            exceptions_output_path_for(locale),
            YAML.dump(exception_rule)
          )
        end
      end

      private

      def after_prepare
        Cldr::Export::Data.dir = requirements[:cldr].common_path
      end

      def segments_root
        @segments_root ||= Utils.deep_symbolize_keys(
          Cldr::Export::Data::SegmentsRoot.new
        )
      end

      def root_output_path_for(boundary_type)
        File.join(params.fetch(:output_path), "#{boundary_type}.yml")
      end

      def exceptions_output_path_for(locale)
        File.join(params.fetch(:output_path), 'exceptions', "#{locale}.yml")
      end

      def exceptions_for(locale)
        cldr_locale = locale.to_s.gsub('-', '_')

        path = File.join(
          requirements[:cldr].common_path,
          'segments', "#{cldr_locale}.xml"
        )

        # for now, ULI exceptions are only available for sentence breaks
        doc = Nokogiri::XML(File.read(path))
        xpath = '//segmentations/segmentation[@type="SentenceBreak"]/suppressions/suppression'

        doc.xpath(xpath).map do |suppression|
          suppression.text
        end
      end

    end
  end
end
