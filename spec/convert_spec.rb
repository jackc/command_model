require 'spec_helper'

describe "CommandModel::Convert" do
  describe "Integer" do
    subject { CommandModel::Convert::Integer.new }

    it "casts to integer when valid string" do
      expect(subject.("42")).to eq(42)
    end

    it "accepts nil" do
      expect(subject.(nil)).to eq(nil)
    end

    it "converts empty string to nil" do
      expect(subject.("")).to eq(nil)
    end

    it "raises TypecastError when invalid string" do
      expect { subject.("asdf") }.to raise_error(CommandModel::Convert::ConvertError)
      expect { subject.("0.1") }.to raise_error(CommandModel::Convert::ConvertError)
    end
  end

  describe "Float" do
    subject { CommandModel::Convert::Float.new }

    it "casts to float when valid string" do
      expect(subject.("42")).to eq(42.0)
      expect(subject.("42.5")).to eq(42.5)
    end

    it "accepts nil" do
      expect(subject.(nil)).to eq(nil)
    end

    it "converts empty string to nil" do
      expect(subject.("")).to eq(nil)
    end

    it "raises TypecastError when invalid string" do
      expect { subject.("asdf") }.to raise_error(CommandModel::Convert::ConvertError)
    end
  end

  describe "Decimal" do
    subject { CommandModel::Convert::Decimal.new }

    it "converts to BigDecimal when valid string" do
      expect(subject.("42")).to eq(BigDecimal("42"))
      expect(subject.("42.5")).to eq(BigDecimal("42.5"))
    end

    it "converts to BigDecimal when float" do
      expect(subject.(42.0)).to eq(BigDecimal("42"))
    end

    it "converts to BigDecimal when int" do
      expect(subject.(42)).to eq(BigDecimal("42"))
    end

    it "accepts nil" do
      expect(subject.(nil)).to eq(nil)
    end

    it "converts empty string to nil" do
      expect(subject.("")).to eq(nil)
    end

    it "raises TypecastError when invalid string" do
      expect { subject.("asdf") }.to raise_error(CommandModel::Convert::ConvertError)
    end
  end

  describe "Date" do
    subject { CommandModel::Convert::Date.new }

    it "casts to date when valid string" do
      expect(subject.("01/01/2000")).to eq(Date.civil(2000,1,1))
      expect(subject.("1/1/2000")).to eq(Date.civil(2000,1,1))
      expect(subject.("2000-01-01")).to eq(Date.civil(2000,1,1))
    end

    it "returns existing date unchanged" do
      date = Date.civil(2000,1,1)
      expect(subject.(date)).to eq(date)
    end

    it "accepts nil" do
      expect(subject.(nil)).to eq(nil)
    end

    it "converts empty string to nil" do
      expect(subject.("")).to eq(nil)
    end

    it "raises TypecastError when invalid string" do
      expect { subject.("asdf") }.to raise_error(CommandModel::Convert::ConvertError)
      expect { subject.("3/50/1290") }.to raise_error(CommandModel::Convert::ConvertError)
    end
  end

  describe "Boolean" do
    subject { CommandModel::Convert::Boolean.new }

    it "casts to true when any non-false value" do
      expect(subject.("true")).to eq(true)
      expect(subject.("t")).to eq(true)
      expect(subject.("1")).to eq(true)
      expect(subject.(true)).to eq(true)
      expect(subject.(Object.new)).to eq(true)
      expect(subject.(42)).to eq(true)
    end

    it "casts to false when false values" do
      expect(subject.("")).to eq(false)
      expect(subject.("0")).to eq(false)
      expect(subject.("f")).to eq(false)
      expect(subject.("false")).to eq(false)
      expect(subject.(0)).to eq(false)
      expect(subject.(nil)).to eq(false)
      expect(subject.(false)).to eq(false)
    end
  end
end
