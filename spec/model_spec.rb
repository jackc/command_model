require 'spec_helper'

class ExampleCommand < CommandModel::Model
  parameter :name, :presence => true
  parameter :title
  parameter :age, typecast: :integer
end

describe CommandModel::Model do
  let(:example_command) { ExampleCommand.new :name => "John" }
  let(:invalid_example_command) { ExampleCommand.new }

  describe "self.parameter" do
    let(:klass) { Class.new(CommandModel::Model) }

    it "creates an attribute reader" do
      klass.parameter :foo
      expect(klass.new.methods).to include(:foo)
    end

    it "creates an attribute writer" do
      klass.parameter :foo
      expect(klass.new.methods).to include(:foo=)
    end

    it "round trips values through writing and reading" do
      klass.parameter :foo
      instance = klass.new
      instance.foo = 42
      expect(instance.foo).to eq(42)
    end

    it "accepts multiple attributes" do
      klass.parameter :foo, :bar
      expect(klass.new.methods).to include(:foo)
      expect(klass.new.methods).to include(:foo=)
      expect(klass.new.methods).to include(:bar)
      expect(klass.new.methods).to include(:bar=)
    end

    it "accepts multiple attributes with typecast" do
      klass.parameter :foo, :bar, :typecast => "integer"
      expect(klass.new.methods).to include(:foo)
      expect(klass.new.methods).to include(:foo=)
      expect(klass.new.methods).to include(:bar)
      expect(klass.new.methods).to include(:bar=)
    end

    it "accepts multiple attributes with validation" do
      klass.parameter :foo, :bar, :presence => true
      expect(klass.new.methods).to include(:foo)
      expect(klass.new.methods).to include(:foo=)
      expect(klass.new.methods).to include(:bar)
      expect(klass.new.methods).to include(:bar=)
    end

    it "creates typecasting writer" do
      klass.send(:define_method, :typecast_42) { |value| 42 }
      klass.parameter :answer, :typecast => "42"
      instance = klass.new
      instance.answer = "foo"
      expect(instance.answer).to eq(42)
    end

    it "creates validations" do
      instance = ExampleCommand.new
      expect(instance).to_not be_valid
      expect(instance.errors[:name]).to be_present
    end
  end

  describe "self.parameters" do
    it "returns all parameters in class" do
      klass = Class.new(CommandModel::Model)
      klass.parameter :name, presence: true
      klass.parameter :birthdate, typecast: :date, presence: true

      expected = [
        CommandModel::Model::Parameter.new(:name, nil, { presence: true }),
        CommandModel::Model::Parameter.new(:birthdate, :date, { presence: true })
      ]

      expect(klass.parameters).to eq(expected)
    end
  end

  describe "self.execute" do
    it "accepts object of same kind and returns it" do
      expect(ExampleCommand.execute(example_command) {}).to eq(example_command)
    end

    it "accepts attributes, creates object, and returns it" do
      c = ExampleCommand.execute(:name => "John") {}
      expect(c).to be_kind_of(ExampleCommand)
      expect(c.name).to eq("John")
    end

    it "calls passed block when there are no validation errors on Model" do
      block_ran = false
      ExampleCommand.execute(example_command) { block_ran = true }
      expect(block_ran).to eq(true)
    end

    it "does not call passed block when there are validation errors on Model" do
      block_ran = false
      ExampleCommand.execute(invalid_example_command) { block_ran = true }
      expect(block_ran).to eq(false)
    end

    it "records execution attempt when there not no validation errors on Model" do
      ExampleCommand.execute(example_command) {}
      expect(example_command.execution_attempted?).to eq(true)
    end

    it "records execution attempt when there are validation errors on Model" do
      ExampleCommand.execute(invalid_example_command) {}
      expect(invalid_example_command.execution_attempted?).to eq(true)
    end

    it "is not successful if block adds error to Model" do
      ExampleCommand.execute(example_command) do |command|
        command.errors.add :base, "foo"
      end

      expect(example_command).to_not be_success
    end
  end

  describe "self.success" do
    it "creates a successful command model" do
      response = ExampleCommand.success
      expect(response).to be_kind_of(ExampleCommand)
      expect(response).to be_success
    end
  end

  describe "self.failure" do
    it "creates a command model with an error" do
      response = ExampleCommand.failure "something broke"
      expect(response).to be_kind_of(ExampleCommand)
      expect(response).to_not be_success
      expect(response.errors[:base]).to eq(["something broke"])
    end
  end


  describe "initialize" do
    it "assigns parameters from hash" do
      m = ExampleCommand.new :name => "John"
      expect(m.name).to eq("John")
    end

    it "assigns parameters from other CommandModel" do
      other = ExampleCommand.new :name => "John"
      m = ExampleCommand.new other
      expect(m.name).to eq(other.name)
    end
  end

  describe "call" do
    context "when valid" do
      it "calls execute" do
        expect(example_command).to receive(:execute)
        example_command.call
      end

      it "returns self" do
        expect(example_command.call).to eq(example_command)
      end
    end

    context "when invalid" do
      it "does not call execute" do
        expect(invalid_example_command).to_not receive(:execute)
        invalid_example_command.call
      end

      it "returns self" do
        expect(invalid_example_command.call).to eq(invalid_example_command)
      end
    end
  end

  describe "execute" do
    it "yields to block with self as argument" do
      block_arg = nil
      example_command.execute do |command|
        block_arg = command
      end

      expect(block_arg).to eq(example_command)
    end
  end

  describe "execution_attempted!" do
    it "sets execution_attempted? to true" do
      example_command.execution_attempted!
      expect(example_command.execution_attempted?).to eq(true)
    end
  end

  describe "success?" do
    it "is false before execution" do
      expect(example_command).to_not be_success
    end

    it "is false after execution with errors" do
      example_command.execution_attempted!
      example_command.errors.add :base, "foo"
      expect(example_command.success?).to eq(false)
    end

    it "is true after execution without errors" do
      example_command.execution_attempted!
      expect(example_command.success?).to eq(true)
    end
  end

  describe "parameters" do
    it "is a hash of all parameter name and values" do
      klass = Class.new(CommandModel::Model)
      klass.parameter :name, presence: true
      klass.parameter :birthdate, typecast: :date, presence: true

      expected = { name: "John", birthdate: Date.new(1980,1,1) }
      instance = klass.new expected
      expect(instance.parameters).to eq(expected)
    end
  end

  describe "set_parameters" do
    it "sets parameters from hash with symbol keys" do
      example_command.set_parameters name: "Bill", title: "Boss"
      expect(example_command.name).to eq("Bill")
      expect(example_command.title).to eq("Boss")
    end

    it "sets parameters from hash with string keys" do
      example_command.set_parameters "name" => "Bill", "title" => "Boss"
      expect(example_command.name).to eq("Bill")
      expect(example_command.title).to eq("Boss")
    end
  end

  describe "typecast_integer" do
    it "casts to integer when valid string" do
      expect(example_command.send(:typecast_integer, "42")).to eq(42)
    end

    it "raises TypecastError when invalid string" do
      expect { example_command.send(:typecast_integer, "asdf") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_integer, nil) }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_integer, "") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_integer, "0.1") }.to raise_error(CommandModel::TypecastError)
    end
  end

  describe "typecast_float" do
    it "casts to float when valid string" do
      expect(example_command.send(:typecast_float, "42")).to eq(42.0)
      expect(example_command.send(:typecast_float, "42.5")).to eq(42.5)
    end

    it "raises TypecastError when invalid string" do
      expect { example_command.send(:typecast_float, "asdf") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_float, nil) }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_float, "") }.to raise_error(CommandModel::TypecastError)
    end
  end

  describe "typecast_decimal" do
    it "converts to BigDecimal when valid string" do
      expect(example_command.send(:typecast_decimal, "42")).to eq(BigDecimal("42"))
      expect(example_command.send(:typecast_decimal, "42.5")).to eq(BigDecimal("42.5"))
    end

    it "converts to BigDecimal when float" do
      expect(example_command.send(:typecast_decimal, 42.0)).to eq(BigDecimal("42"))
    end

    it "converts to BigDecimal when int" do
      expect(example_command.send(:typecast_decimal, 42)).to eq(BigDecimal("42"))
    end

    it "raises TypecastError when invalid string" do
      expect { example_command.send(:typecast_decimal, "asdf") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_decimal, nil) }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_decimal, "") }.to raise_error(CommandModel::TypecastError)
    end
  end

  describe "typecast_date" do
    it "casts to date when valid string" do
      expect(example_command.send(:typecast_date, "01/01/2000")).to eq(Date.civil(2000,1,1))
      expect(example_command.send(:typecast_date, "1/1/2000")).to eq(Date.civil(2000,1,1))
      expect(example_command.send(:typecast_date, "2000-01-01")).to eq(Date.civil(2000,1,1))
    end

    it "returns existing date unchanged" do
      date = Date.civil(2000,1,1)
      expect(example_command.send(:typecast_date, date)).to eq(date)
    end

    it "raises TypecastError when invalid string" do
      expect { example_command.send(:typecast_date, "asdf") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_date, nil) }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_date, "") }.to raise_error(CommandModel::TypecastError)
      expect { example_command.send(:typecast_date, "3/50/1290") }.to raise_error(CommandModel::TypecastError)
    end
  end

  describe "typecast_boolean" do
    it "casts to true when any non-false value" do
      expect(example_command.send(:typecast_boolean, "true")).to eq(true)
      expect(example_command.send(:typecast_boolean, "t")).to eq(true)
      expect(example_command.send(:typecast_boolean, "1")).to eq(true)
      expect(example_command.send(:typecast_boolean, true)).to eq(true)
      expect(example_command.send(:typecast_boolean, Object.new)).to eq(true)
      expect(example_command.send(:typecast_boolean, 42)).to eq(true)
    end

    it "casts to false when false values" do
      expect(example_command.send(:typecast_boolean, "")).to eq(false)
      expect(example_command.send(:typecast_boolean, "0")).to eq(false)
      expect(example_command.send(:typecast_boolean, "f")).to eq(false)
      expect(example_command.send(:typecast_boolean, "false")).to eq(false)
      expect(example_command.send(:typecast_boolean, 0)).to eq(false)
      expect(example_command.send(:typecast_boolean, nil)).to eq(false)
      expect(example_command.send(:typecast_boolean, false)).to eq(false)
    end
  end

  it "does not consider nil a typecast error" do
    example_command.name = "Test"
    example_command.age = nil
    expect(example_command).to be_valid
  end

  it "includes typecasting errors in validations" do
    example_command.instance_variable_get(:@typecast_errors)["name"] = "integer"
    expect(example_command).to_not be_valid
    expect(example_command.errors["name"]).to be
  end

  it "does not include typecasting error in validations if the attribute already has an error" do
    invalid_example_command.instance_variable_get(:@typecast_errors)["name"] = "integer"
    expect(invalid_example_command).to_not be_valid
    expect(invalid_example_command.errors["name"]).to be
    expect(invalid_example_command.errors["name"].find { |e| e =~ /integer/ }).to_not be
  end


end
