# CommandModel

Domain models usually have richer behavior than can be represented with a
typical ActiveRecord style update_attributes.

    # yuck!
    account.update_attributes :balance => account.balance - 50 
    
    # much better
    account.withdraw :amount => 50
    
But there are multiple complications with the OO approach. How do we integrate
Rails style validations? How are user-supplied strings typecast? How do we
know if the command succeeded? CommandModel solves these problems. CommandModel
is an ActiveModel based class that encapsulates validations and typecasting
for command execution.
    
## Installation

Add this line to your application's Gemfile:

    gem 'command_model'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install command_model

## Usage

Create a class derived from CommandModel::Model to represent the command
request.

    class WithdrawCommand < CommandModel::Model
      parameter :amount,
        :typecast => :integer,
        :presence => true,
        :numericality => { :greater_than => 0, :less_than_or_equal_to => 500 }
    end
    
Create the method to run the command. This method should call the class method
execute on the command class and pass it the options it received. It will
accept either a command object or a hash of attributes. It must pass execute
a block that actually does the work. The block will only be called if
the validations in the command object pass. The execute block is free to do
any further validations that only can be done during execution. If it adds
any errors to the command object then the command will be considered to have
failed. Finally the execute method will return the command object.

    class Account
      # ...
      
      def withdraw(options)
        WithdrawCommand.execute(options) do |command|
          if balance >= command.amount
            @balance -= command.amount
          else
            command.errors.add :amount, "is more than account balance"
          end
        end
      end
      
      # ...
    end
    
Use example:

    response = account.withdraw :amount => 50
    
    if response.success?
      puts "Success!"
    else
      puts "Errors:"
      puts response.errors.full_messages
    end
    
## Other uses

This could be used to wrap database generated errors into normal Rails
validations. For example, database level uniqueness constraint errors could
show up in errors the same as validates_uniqueness_of. validates_uniqueness_of
could even be removed for a marginal performance boost as the database should
be doing a uniqueness check anyway.

# Examples

There is a simple Rails application in examples/bank that demonstrates the
integration of Rails form helpers and validations with CommandModel.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
