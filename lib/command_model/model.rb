module CommandModel
  class TypecastError < StandardError
    attr_reader :original_error

    def initialize(original_error)
      @original_error = original_error
    end
  end

  class Model
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    Parameter = Struct.new(:name, :typecast, :validations)

    # Parameter requires one or more attributes as its first parameter(s).
    # It accepts an options hash as its last parameter.
    #
    # ==== Options
    #
    # * typecast - The type of object to typecast to. Typecasts are built-in
    #   for integer, float, and date. Additional typecasts can be defined
    #   by defining a method typecast_#{name} for a typecast of #{name}.
    # * validations - All other options are considered validations and are
    #   passed to ActiveModel::Validates.validates
    #
    # ==== Examples
    #
    #   parameter :gender
    #   parameter :name, :presence => true
    #   parameter :birthdate, :typecast => :date
    #   parameter :height, :weight,
    #     :typecast => :integer,
    #     :presence => true,
    #     :numericality => { :greater_than_or_equal_to => 0 }
    def self.parameter(*args)
      options = args.last.kind_of?(Hash) ? args.pop.clone : {}
      typecast = options.delete(:typecast)

      args.each do |name|
        attr_reader name

        if typecast
          attr_typecasting_writer name, typecast
        else
          attr_writer name
        end
        validates name, options.clone if options.present? # clone options because validates mutates the hash :(
        parameters.push Parameter.new name, typecast, options
      end
    end

    # Returns array of all parameters defined for class
    def self.parameters
      @parameters ||= []
    end

    def self.attr_typecasting_writer(name, target_type) #:nodoc
      eval <<-END_EVAL
        public def #{name}=(value)
          @#{name} = value != nil ? typecast_#{target_type}(value) : nil
          @typecast_errors.delete("#{name}")
          @#{name}
        rescue TypecastError
          @typecast_errors["#{name}"] = "#{target_type}"
          @#{name} = value
        end
      END_EVAL
    end

    # Executes a block of code if the command model is valid.
    #
    # Accepts either a command model or a hash of attributes with which to
    # create a new command model.
    #
    # ==== Examples
    #
    #   RenameUserCommand.execute(:login => "john") do |command|
    #     if allowed_to_rename_user?
    #       self.login = command.login
    #     else
    #       command.errors.add :base, "not allowed to rename"
    #     end
    #   end
    def self.execute(attributes_or_command, &block)
      command = if attributes_or_command.kind_of? self
        attributes_or_command
      else
        new(attributes_or_command)
      end

      command.call &block
    end

    # Quickly create a successful command object. This is used when the
    # command takes no parameters to want to take advantage of the success?
    # and errors properties of a command object.
    def self.success
      new.tap do |instance|
        instance.execution_attempted!
      end
    end

    # Quickly create a failed command object. Requires one parameter with
    # the description of what went wrong. This is used when the
    # command takes no parameters to want to take advantage of the success?
    # and errors properties of a command object.
    def self.failure(error)
      new.tap do |instance|
        instance.execution_attempted!
        instance.errors.add(:base, error)
      end
    end

    # Accepts a parameters hash or another of the same class. If another
    # instance of the same class is passed in then the parameters are copied
    # to the new object.
    def initialize(parameters={})
      @typecast_errors = {}
      set_parameters parameters
    end

    # Executes the command by calling the method +execute+ if the validations
    # pass.
    def call(&block)
      execute(&block) if valid?
      execution_attempted!
      self
    end

    # Performs the actual command execution. It does not test if the command
    # parameters are valid. Typically, +call+ should be called instead of
    # calling +execute+ directly.
    #
    # +execute+ should be overridden in descendent classes
    def execute
      yield self if block_given?
    end

    # Record that an attempt was made to execute this command whether or not
    # it was successful.
    def execution_attempted! #:nodoc:
      @execution_attempted = true
    end

    # True if execution has been attempted on this command
    def execution_attempted?
      @execution_attempted
    end

    # Command has been executed without errors
    def success?
      execution_attempted? && errors.empty?
    end

    # Returns hash of all parameter names and values
    def parameters
      self.class.parameters.each_with_object({}) do |parameter, hash|
        hash[parameter.name] = send(parameter.name)
      end
    end

    # Sets parameter(s) from hash or instance of same class
    def set_parameters(hash_or_instance)
      parameters = extract_parameters_from_hash_or_instance(hash_or_instance)
      parameters.each do |k,v|
        send "#{k}=", v
      end
    end

    #:nodoc:
    def persisted?
      false
    end

    private
      def extract_parameters_from_hash_or_instance(hash_or_instance)
        if hash_or_instance.respond_to?(:parameters)
          hash_or_instance.parameters
        else
          hash_or_instance
        end
      end

      def typecast_integer(value)
        Integer(value)
      rescue StandardError => e
        raise TypecastError.new(e)
      end

      def typecast_decimal(value)
        BigDecimal(value, 16)
      rescue StandardError => e
        raise TypecastError.new(e)
      end

      def typecast_float(value)
        Float(value)
      rescue StandardError => e
        raise TypecastError.new(e)
      end

      def typecast_date(value)
        return value if value.kind_of? Date
        value = value.to_s
        if value =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/
          Date.civil($1.to_i, $2.to_i, $3.to_i)
        else
          Date.strptime(value, "%m/%d/%Y")
        end
      rescue StandardError => e
        raise TypecastError.new(e)
      end

      def typecast_boolean(value)
        case value
        when "", "0", "false", "f", 0
          then false
        else
          !!value
        end
      end

      def include_typecasting_errors
        @typecast_errors.each do |attribute, target_type|
          unless errors[attribute].present?
            errors.add attribute, "is not a #{target_type}"
          end
        end
      end

      # overriding this to make typecasting errors run at the end so they will
      # not run if there is already an error on the column. Otherwise, when
      # typecasting to an integer and using validates_numericality_of two
      # errors will be generated.
      def run_validations!
        super
        include_typecasting_errors
        errors.empty?
      end
  end
end
