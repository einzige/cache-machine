require 'spec_helper'

describe CacheMachine::Cache::Mapper do
  subject { CacheMachine::Cache::Mapper.new }

  its(:scope) { should == :root }

  describe "#resource" do
    before :each do
      subject.resource(Cacher)
    end

    it "makes module be a resource" do
      Cacher.include?(CacheMachine::Cache::Resource).should be_true
    end

    it "changes scope back" do
      subject.scope.should == :root
    end

    it "registers model" do
      CacheMachine::Cache::Map.registered_models.should == [Cacher]
    end
  end

  describe "#collection" do
    let(:register_options) do
      { :scope   => nil,
        :on      => :after_save,
        :members => { :one => {}, :two => {} }
      }
    end

    before :each do
      Join.should_receive(:register_cache_dependency).with(Cacher, :joins, register_options)

      subject.resource(Cacher) do
        collection(:joins) do
          member :one
          member :two
        end
      end
    end

    it "includes collection module in associated class" do
      Join.include?(CacheMachine::Cache::Collection).should be_true
    end

    it "changes scope back" do
      subject.scope.should == :root
    end

    it "raises an exception when collection is not defined as an association" do
      lambda {
        subject.resource(Cacher) do
          collection :unexisted_relation
        end
      }.should raise_error(ArgumentError, "Relation 'unexisted_relation' is not set on the class Cacher")
    end
  end
end
