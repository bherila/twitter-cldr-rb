# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Segmentation

    class RuleSet
      class << self
        def build_new(locale, boundary_type, options = {})
          rules = state_tables_for(boundary_type).map do |state_table|
            rule_for(state_table)
          end

          new(boundary_type, locale, rules, options)
        end

        # we only support exceptions for the "sentence" boundary type for now
        def exception_rule_for(locale, boundary_type)
          state_table = exception_state_table_for(locale)
          rule_for(state_table)
        end

        private

        def rule_for(state_table)
          left = State.new(state_table[:left])
          right = State.new(state_table[:right])
          klass = boundary_class_for(state_table[:boundary_symbol])
          klass.new(left, right, state_table[:id], state_table[:string])
        end

        def boundary_class_for(boundary_symbol)
          case boundary_symbol
            when :break then BreakRule
            when :no_break then NoBreakRule
          end
        end

        def state_tables_for(boundary_type)
          state_table_cache[boundary_type] ||= begin
            resources = TwitterCldr.get_resource(
              'segmentation', 'state_tables', boundary_type
            )

            resources.map do |resource|
              state_table_from_resource(resource)
            end
          end
        end

        def exception_state_table_for(locale)
          exceptions_cache[locale] ||= begin
            state_table_from_resource(
              TwitterCldr.get_resource(
                'segmentation', 'state_tables', 'exceptions', locale
              )
            )
          end
        end

        def state_table_from_resource(resource)
          resource.merge(
            left: StateTable.new(
              resource[:left][:table], resource[:left][:exit_state]
            ),

            right: StateTable.new(
              resource[:right][:table], resource[:right][:exit_state]
            )
          )
        end

        def state_table_cache
          @state_table_cache ||= {}
        end

        def exceptions_cache
          @exceptions_cache ||= {}
        end
      end

      attr_reader :boundary_type, :locale, :rules, :use_uli_exceptions
      alias :use_uli_exceptions? :use_uli_exceptions

      def initialize(boundary_type, locale, rules, options = {})
        @boundary_type = boundary_type
        @locale = locale
        @rules = rules

        @implicit_break = BreakRule.new(
          State.new({}), State.new({}), :implicit_break, ''
        )

        @use_uli_exceptions = options.fetch(
          :use_uli_exceptions, false
        )

        reset
      end

      def supports_exceptions?
        boundary_type == 'sentence'
      end

      def reset
        reset_rules
        @boundary_cache = {}
      end

      def find_match(cursor)
        reset_rules
        counter = cursor.position
        rules = each_rule.to_a

        until rules.empty?
          rules.reject! do |rule|
            if rule.terminal?
              @boundary_cache[counter - rule.right.num_accepted] ||= rule
            elsif !rule.accept(cursor.codepoints[counter])
              # need to check terminal? again because we just called #accept
              # on the rule
              if rule.terminal?
                @boundary_cache[counter - rule.right.num_accepted] ||= rule
              end

              true
            else
              false
            end
          end

          counter += 1
        end

        if match = @boundary_cache[cursor.position]
          @boundary_cache.delete(cursor.position)
          match
        else
          @implicit_break
        end
      end

      def exception_rule
        @exception_rule ||= self.class.exception_rule_for(
          locale, boundary_type
        )
      end

      def each_rule(&block)
        return to_enum(__method__) unless block_given?
        # @TODO: handle ULI exceptions
        yield exception_rule if use_uli_exceptions? && supports_exceptions?
        rules.each(&block)
      end

      private

      def reset_rules
        each_rule(&:reset)
      end
    end

  end
end
