class Account
  class WithdrawCommand < CommandModel::Model
    parameter :amount,
      :typecast => :integer,
      :presence => true,
      :numericality => { :greater_than => 0, :less_than_or_equal_to => 500 }
  end
  
  class DepositCommand < CommandModel::Model
    parameter :amount,
      :typecast => :integer,
      :presence => true,
      :numericality => { :greater_than => 0 }
  end
  
  class TransferCommand < CommandModel::Model
    parameter :from, :to, :presence => true
    parameter :amount,
      :typecast => :integer,
      :presence => true,
      :numericality => { :greater_than => 0 }
      
    validate do |model|
      errors.add :base, "From and to accounts cannot be the same" if model.from == model.to
    end
  end    

  attr_reader :name, :balance
  
  def initialize(name, balance)
    @name = name
    @balance = balance
  end
  
  def withdraw(options)
    WithdrawCommand.execute(options) do |command|
      if balance >= command.amount
        @balance -= command.amount
      else
        command.errors.add :amount, "is more than account balance"
      end
    end
  end
  
  def deposit(options)
    DepositCommand.execute(options) do |command|
      @balance += command.amount
    end
  end
  
  def self.transfer(options)
    TransferCommand.execute(options) do |command|
      if command.from.balance >= command.amount
        command.from.withdraw :amount => command.amount
        command.to.deposit :amount => command.amount
      else
        command.errors.add :amount, "is more than account balance"
      end
    end
  end
  
  def to_param
    name
  end
end
