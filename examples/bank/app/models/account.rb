class Account
  class WithdrawCommand < CommandModel::Model
    parameter :amount,
      typecast: :integer,
      presence: true,
      numericality: { greater_than: 0, less_than_or_equal_to: 500 }
  end
  
  class DepositCommand < CommandModel::Model
    parameter :amount,
      typecast: :integer,
      presence: true,
      numericality: { greater_than: 0 }
  end  

  attr_reader :name, :balance
  
  def initialize(name, balance)
    @name = name
    @balance = balance
  end
  
  def withdraw(args)
    WithdrawCommand.new(args).call do |command|
      if balance >= command.amount
        @balance -= command.amount
      else
        command.errors.add :amount, "is more than account balance"
      end
    end
  end
  
  def deposit(args)
    DepositCommand.new(args).call do |command|
      @balance += command.amount
    end
  end
  
  def to_param
    name
  end

  def self.all
    ACCOUNTS
  end

  def self.find_by_name(name)
    all.find { |a| a.name == name }
  end
end
