class Transfer < CommandModel::Model
  parameter :from_name, :to_name, presence: true
  parameter :amount,
    typecast: :integer,
    presence: true,
    numericality: { greater_than: 0 }

  validate do |model|
    { from_name: from, to_name: to }.each do |key, value|
      errors.add key, "is not a valid account name" unless value
    end
  end
    
  validate do |model|
    errors.add :base, "From and to accounts cannot be the same" if model.from == model.to
  end

  def call
    if from.balance >= amount
      from.withdraw amount: amount
      to.deposit amount: amount
    else
      errors.add :amount, "is more than account balance"
    end
  end

  def from
    Account.find_by_name from_name
  end

  def to
    Account.find_by_name to_name
  end
end