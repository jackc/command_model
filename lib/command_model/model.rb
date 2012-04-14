module CommandModel
  class Model
    include ActiveModel::Validations
    
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
      attributes.each do |k,v|
        send "#{k}=", v
      end
    end
    
    # Record that an attempt was made to execute this command whether or not
    # it was successful.
    def execution_attempted!
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
  end
end
