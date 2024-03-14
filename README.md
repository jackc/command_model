# CommandModel

CommandModel is an ActiveModel based class that encapsulates the user
interaction logic that wraps a domain operation. This user interaction typically
may include sanitizing, validating, normalizing, and type converting input. It
also will include the response from the domain operation.

There are three major concerns when handling a user request: input handling,
domain logic, and persistence. ActiveRecord mixes all three of these concerns
together. While this is very convenient for simple CRUD, it becomes difficult
to work with once your domain operations become more complex. Domain models
usually have richer behavior than can be represented with a typical
ActiveRecord style update_attributes.

```ruby
# yuck!
account.update_attributes balance: account.balance - 50

# much better
account.withdraw amount: 50
```

But there are multiple complications with the OO approach. How do we integrate
Rails style validations? How are user-supplied strings type converted? How do we
know if the command succeeded? CommandModel solves these problems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'command_model'
```

And then execute:

```console
$ bundle
```

Or install it yourself as:

```console
$ gem install command_model
```

## Usage

Create a class derived from CommandModel::Model to represent the command
request.

```ruby
class WithdrawCommand < CommandModel::Model
  parameter :amount,
    convert: :integer,
    presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 500 }
end
```

Create the method to run the command. This method should instantiate and call a new command object. It must pass call
a block that actually does the work. The block will only be called if
the validations in the command object pass. The block is free to do
any further validations that only can be done during execution. If it adds
any errors to the command object then the command will be considered to have
failed. Finally, the call method will return self.

```ruby
class Account
  # ...

  def withdraw(args)
    WithdrawCommand.new(args).call do |command|
      if balance >= command.amount
        @balance -= command.amount
      else
        command.errors.add :amount, "is more than account balance"
      end
    end
  end

  # ...
end
```

Use example:

```ruby
response = account.withdraw amount: 50

if response.success?
  puts "Success!"
else
  puts "Errors:"
  puts response.errors.full_messages
end
```

## Mixing in Domain Logic

In a pure OO world the domain logic for actually executing a command may
belong in another class. However, it is possible to mix in that logic directly
into the command object. This can easily be done by overriding the execute
method. The execute method is called by the call method if all validations
succeed. The following is a reimplementation of the previous example with
internal domain logic.

```ruby
class WithdrawCommand < CommandModel::Model
  parameter :amount,
    convert: :integer,
    presence: true,
    numericality: { greater_than: 0, less_than_or_equal_to: 500 }
  parameter :account_id, presence: true

  def execute
    account = Account.find_by_id account_id
    unless account
      errors.add :account_id, "not found"
      return
    end

    if account.balance >= amount
      account.balance -= amount
    else
      errors.add :amount, "is more than account balance"
    end
  end
end
```

## Other uses

This could be used to wrap database generated errors into normal Rails
validations. For example, database level uniqueness constraint errors could
show up in errors the same as validates_uniqueness_of. validates_uniqueness_of
could even be removed for a marginal performance boost as the database should
be doing a uniqueness check anyway.

## Examples

There is a simple Rails application in examples/bank that demonstrates the
integration of Rails form helpers and validations with CommandModel.

## Version History

* 2.0.1 - April 3, 2023
    * Date parsing allows 5 digit years
* 2.0 - April 11, 2018
    * Rename typecast parameter option to convert
    * Any callable object can be used as a type converter
    * Multiple type converters can be chained together
    * Added StringMutator type converter
    * Add boolean type conversion
* 1.3 - February 13, 2018
    * Add decimal type cast
* 1.2 - October 24, 2014
    * Suport Rails 4
* 1.1 - November 13, 2012
    * Updated documentation and example application
    * Refactored Model to support internal domain logic easier with #call and #execute.
    * Model#initialize can now copy another model
    * Added Model#set_parameters
    * Added Model.parameters
* 1.0 - April 14, 2012
    * Initial public release

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
