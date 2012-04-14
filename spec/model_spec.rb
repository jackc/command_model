require 'spec_helper'

class ExampleCommand < CommandModel::Model
  attr_accessor :name
  
  validates_presence_of :name
end

describe CommandModel::Model do
  let(:example_command) { ExampleCommand.new :name => "John" }
  let(:invalid_example_command) { ExampleCommand.new }

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
end
