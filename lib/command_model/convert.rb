require 'bigdecimal'
require 'date'

module CommandModel
  module Convert
    class ConvertError < StandardError
      attr_reader :original_error, :target_type

      def initialize(original_error, target_type)
        @original_error = original_error
        @target_type = target_type
      end
    end

    class StringMutator
      def initialize(force_to_s=false, &block)
        @force_to_s = force_to_s
        @mutator = block
      end

      def call(value)
        if @force_to_s
          @mutator.call value.to_s
        elsif value.respond_to? :to_str
          @mutator.call value.to_str
        else
          value
        end
      end
    end

    class Integer
      def call(value)
        return nil if value.blank?
        Integer(value)
      rescue StandardError => e
        raise ConvertError.new(e, "integer")
      end
    end

    class Decimal
      def call(value)
        return nil if value.blank?
        BigDecimal(value, 16)
      rescue StandardError => e
        raise ConvertError.new(e, "number")
      end
    end

    class Float
      def call(value)
        return nil if value.blank?
        Float(value)
      rescue StandardError => e
        raise ConvertError.new(e, "number")
      end
    end

    class Date
      def call(value)
        return nil if value.blank?
        return value if value.kind_of? Date
        value = value.to_s
        if value =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/
          ::Date.civil($1.to_i, $2.to_i, $3.to_i)
        else
          ::Date.strptime(value, "%m/%d/%Y")
        end
      rescue StandardError => e
        raise ConvertError.new(e, "date")
      end
    end

    class Boolean
      def call(value)
        case value
        when "", "0", "false", "f", 0
          then false
        else
          !!value
        end
      end
    end
  end
end
