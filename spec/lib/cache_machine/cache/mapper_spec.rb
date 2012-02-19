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
  end

  # TODO (SZ): missing specs
end