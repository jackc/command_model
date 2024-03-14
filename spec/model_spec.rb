require 'spec_helper'

class ExampleCommand < CommandModel::Model
  parameter :name, presence: true
  parameter :title
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

    it "accepts multiple attributes with convert" do
      klass.parameter :foo, :bar, :convert => :integer
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

    it "converts via callable" do
      klass.parameter :answer, convert: ->(value) { 42 }
      instance = klass.new
      instance.answer = "foo"
      expect(instance.answer).to eq(42)
    end

    it "converts with multiple converters" do
      klass.parameter :num, convert: [CommandModel::Convert::StringMutator.new { |s| s.gsub(",", "")}, :integer]
      instance = klass.new
      instance.num = "1,000"
      expect(instance.num).to eq(1000)
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
      klass.parameter :birthdate, convert: :date, presence: true

      expected = [
        CommandModel::Model::Parameter.new(:name, nil, { presence: true }),
        CommandModel::Model::Parameter.new(:birthdate, :date, { presence: true })
      ]

      expect(klass.parameters).to eq(expected)
    end
  end

  describe "self.dependency" do
    let(:klass) { Class.new(CommandModel::Model) }

    it "creates an attribute reader" do
      klass.dependency :foo
      expect(klass.new.methods).to include(:foo)
    end

    it "accepts multiple attributes" do
      klass.dependency :foo, :bar
      expect(klass.new.methods).to include(:foo)
      expect(klass.new.methods).to include(:bar)
    end

    it "accepts multiple attributes with default" do
      klass.dependency :foo, :bar, default: -> { "baz" }
      expect(klass.new.methods).to include(:foo)
      expect(klass.new.methods).to include(:bar)
    end
  end

  describe "self.dependencies" do
    it "returns all dependencies in class" do
      klass = Class.new(CommandModel::Model)
      klass.dependency :foo
      klass.dependency :bar

      expect(klass.dependencies.map(&:name)).to eq([:foo, :bar])
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

    it "uses default dependencies when not provided" do
      klass = Class.new(CommandModel::Model)
      klass.dependency :stdout, default: -> { $stdout }
      klass.parameter :name
      m = klass.execute(:name => "John")
      expect(m.stdout).to eq($stdout)
      expect(m.execution_attempted?).to eq(true)
    end

    it "accepts dependencies from arguments" do
      klass = Class.new(CommandModel::Model)
      klass.dependency :stdout, default: -> { $stdout }
      klass.parameter :name
      writer = StringIO.new
      m = klass.execute({:name => "John"}, :stdout => writer)
      expect(m.stdout).to eq(writer)
      expect(m.execution_attempted?).to eq(true)
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

    it "assigns default dependencies when not provided" do
      klass = Class.new(CommandModel::Model)
      klass.dependency :stdout, default: -> { $stdout }
      klass.parameter :name
      m = klass.new :name => "John"
      expect(m.stdout).to eq($stdout)
    end

    it "assigns dependencies from arguments" do
      klass = Class.new(CommandModel::Model)
      klass.dependency :stdout, default: -> { $stdout }
      klass.parameter :name
      writer = StringIO.new
      m = klass.new({:name => "John"}, :stdout => writer)
      expect(m.stdout).to eq(writer)
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
      klass.parameter :birthdate, convert: :date, presence: true

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

  it "includes type conversion errors in validations" do
    example_command.instance_variable_get(:@type_conversion_errors)["name"] = "integer"
    expect(example_command).to_not be_valid
    expect(example_command.errors["name"]).to be
  end

  it "does not include type conversion error in validations if the attribute already has an error" do
    invalid_example_command.instance_variable_get(:@type_conversion_errors)["name"] = "integer"
    expect(invalid_example_command).to_not be_valid
    expect(invalid_example_command.errors["name"]).to be
    expect(invalid_example_command.errors["name"].find { |e| e =~ /integer/ }).to_not be
  end
end
