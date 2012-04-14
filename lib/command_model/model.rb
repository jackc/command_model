module CommandModel
  class Model
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming
    
    validate :include_typecasting_errors
    
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
        
        validates name, options if options.present?
      end
    end
    
    def self.attr_typecasting_writer(name, target_type) #:nodoc
      eval <<-END_EVAL
        def #{name}=(value)
          typecast_value = typecast_#{target_type}(value)
          if typecast_value
            @typecast_errors.delete("#{name}")
            @#{name} = typecast_value
          else
            @typecast_errors["#{name}"] = "#{target_type}"
            @#{name} = value
          end
          
          @#{name}
        end
      END_EVAL
    end
    
    def self.execute(attributes_or_command)
      command = if attributes_or_command.kind_of? self
        attributes_or_command
      else
        new(attributes_or_command)
      end
      
      yield command if command.valid?
      command.execution_attempted!   
      command
    end
    
    def initialize(attributes={})
      @typecast_errors = {}
      
      attributes.each do |k,v|
        send "#{k}=", v
      end
    end
    
    # Record that an attempt was made to execute this command whether or not
    # it was successful.
    def execution_attempted! #:nodoc
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
    
    def persisted?
      false
    end
    
    private
      def typecast_integer(value)
        Integer(value) rescue nil
      end
      
      def typecast_float(value)
        Float(value) rescue nil
      end
      
      def typecast_date(value)
        return value if value.kind_of? Date
        value = value.to_s
        if value =~ /\A(\d\d\d\d)-(\d\d)-(\d\d)\z/
          Date.civil($1.to_i, $2.to_i, $3.to_i) rescue nil
        else
          Date.strptime(value, "%m/%d/%Y") rescue nil
        end
      end
      
      def include_typecasting_errors
        @typecast_errors.each do |attribute, target_type|
          errors.add attribute, "is not a #{target_type}"
        end
      end
  end
end
