require 'spec_helper'

class ExampleCommand < CommandModel::Model
  parameter :name, :presence => true
end

describe CommandModel::Model do
  let(:example_command) { ExampleCommand.new :name => "John" }
  let(:invalid_example_command) { ExampleCommand.new }
  
  describe "self.parameter" do
    let(:klass) { Class.new(CommandModel::Model) }
    
    it "creates an attribute reader" do
      klass.parameter :foo
      klass.new.methods.should include(:foo)
    end
    
    it "creates an attribute writer" do
      klass.parameter :foo
      klass.new.methods.should include(:foo=)
    end
    
    it "round trips values through writing and reading" do
      klass.parameter :foo
      instance = klass.new
      instance.foo = 42
      instance.foo.should eq(42)
    end
    
    it "accepts multiple attributes" do
      klass.parameter :foo, :bar
      klass.new.methods.should include(:foo)
      klass.new.methods.should include(:foo=)
      klass.new.methods.should include(:bar)
      klass.new.methods.should include(:bar=)
    end
    
    it "accepts multiple attributes with typecast" do
      klass.parameter :foo, :bar, :typecast => "integer"
      klass.new.methods.should include(:foo)
      klass.new.methods.should include(:foo=)
      klass.new.methods.should include(:bar)
      klass.new.methods.should include(:bar=)
    end
    
    it "accepts multiple attributes with validation" do
      klass.parameter :foo, :bar, :presence => true
      klass.new.methods.should include(:foo)
      klass.new.methods.should include(:foo=)
      klass.new.methods.should include(:bar)
      klass.new.methods.should include(:bar=)
    end
    
    it "creates typecasting writer" do
      klass.send(:define_method, :typecast_42) { |value| 42 }
      klass.parameter :answer, :typecast => "42"
      instance = klass.new
      instance.answer = "foo"
      instance.answer.should eq(42)
    end
    
    it "creates validations" do
      instance = ExampleCommand.new
      instance.should_not be_valid
      instance.errors[:name].should be_present
    end    
  end
  

  describe "self.execute" do
    it "accepts object of same kind and returns it" do
      ExampleCommand.execute(example_command) {}.should eq(example_command)
    end
    
    it "accepts attributes, creates object, and returns it" do
      c = ExampleCommand.execute(:name => "John") {}
      c.should be_kind_of(ExampleCommand)
      c.name.should eq("John")
    end
    
    it "calls passed block when there are no validation errors on Model" do
      block_ran = false
      ExampleCommand.execute(example_command) { block_ran = true }
      block_ran.should eq(true)       
    end
    
    it "does not call passed block when there are validation errors on Model" do
      block_ran = false
      ExampleCommand.execute(invalid_example_command) { block_ran = true }
      block_ran.should eq(false)
    end
    
    it "records execution attempt when there not no validation errors on Model" do
      ExampleCommand.execute(example_command) {}
      example_command.execution_attempted?.should eq(true)
    end
    
    it "records execution attempt when there are validation errors on Model" do
      ExampleCommand.execute(invalid_example_command) {}
      invalid_example_command.execution_attempted?.should eq(true)
    end
    
    it "is not successful if block adds error to Model" do
      ExampleCommand.execute(example_command) do |command|
        command.errors.add :base, "foo"
      end
      
      example_command.should_not be_success
    end
  end
  
  describe "self.success" do
    it "creates a successful command model" do
      response = ExampleCommand.success
      response.should be_kind_of(ExampleCommand)
      response.should be_success
    end
  end
  
  describe "self.failure" do
    it "creates a command model with an error" do
      response = ExampleCommand.failure "something broke"
      response.should be_kind_of(ExampleCommand)
      response.should_not be_success
      response.errors[:base].should eq(["something broke"])
    end
  end
  

  describe "initialize" do
    it "assigns attributes" do
      m = ExampleCommand.new :name => "John"
      m.name.should eq("John")
    end
  end
  
  describe "execution_attempted!" do
    it "sets execution_attempted? to true" do
      example_command.execution_attempted!
      example_command.execution_attempted?.should eq(true)
    end
  end
  
  describe "success?" do
    it "is false before execution" do
      example_command.should_not be_success
    end
    
    it "is false after execution with errors" do
      example_command.execution_attempted!
      example_command.errors.add :base, "foo"
      example_command.success?.should eq(false)
    end
    
    it "is true after execution without errors" do
      example_command.execution_attempted!
      example_command.success?.should eq(true)
    end
  end
  
  describe "typecast_integer" do
    it "casts to integer when valid string" do
      example_command.send(:typecast_integer, "42").should eq(42)
    end
    
    it "returns nil when invalid string" do
      example_command.send(:typecast_integer, "asdf").should be_nil
      example_command.send(:typecast_integer, nil).should be_nil
      example_command.send(:typecast_integer, "").should be_nil
      example_command.send(:typecast_integer, "0.1").should be_nil
    end
  end
  
  describe "typecast_float" do
    it "casts to float when valid string" do
      example_command.send(:typecast_float, "42").should eq(42.0)
      example_command.send(:typecast_float, "42.5").should eq(42.5)
    end
    
    it "returns nil when invalid string" do
      example_command.send(:typecast_float, "asdf").should be_nil
      example_command.send(:typecast_float, nil).should be_nil
      example_command.send(:typecast_float, "").should be_nil
    end
  end
  
  describe "typecast_date" do
    it "casts to date when valid string" do
      example_command.send(:typecast_date, "01/01/2000").should eq(Date.civil(2000,1,1))
      example_command.send(:typecast_date, "1/1/2000").should eq(Date.civil(2000,1,1))
      example_command.send(:typecast_date, "2000-01-01").should eq(Date.civil(2000,1,1))
    end
    
    it "returns existing date unchanged" do
      date = Date.civil(2000,1,1)
      example_command.send(:typecast_date, date).should eq(date)
    end
    
    it "returns nil when invalid string" do
      example_command.send(:typecast_date, "asdf").should be_nil
      example_command.send(:typecast_date, nil).should be_nil
      example_command.send(:typecast_date, "").should be_nil
      example_command.send(:typecast_date, "3/50/1290").should be_nil
    end
  end
  
  it "includes typecasting errors in validations" do
    example_command.instance_variable_get(:@typecast_errors)["name"] = "integer"
    example_command.should_not be_valid
    example_command.errors["name"].should be
  end
  
  it "does not include typecasting error in validations if the attribute already has an error" do
    invalid_example_command.instance_variable_get(:@typecast_errors)["name"] = "integer"
    invalid_example_command.should_not be_valid
    invalid_example_command.errors["name"].should be
    invalid_example_command.errors["name"].find { |e| e =~ /integer/ }.should_not be
  end
  
  
end
