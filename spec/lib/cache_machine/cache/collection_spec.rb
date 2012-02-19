require 'spec_helper'

describe CacheMachine::Cache::Collection do

  let(:cacher) { cacher = Cacher.create }
  let(:join)   { cacher.joins.create    }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher do
        collection :joins do
          member :one
          member :two
        end
      end
    end
  end

  describe "#register_cache_dependency" do
    let(:register_options) do
      { :scope   => nil,
        :on      => :after_save,
        :members => { :one => {}, :two => {} }
      }
    end

    it "registers cache memebers" do
      Join.cache_map_members.should == { Cacher => { :joins => register_options} }
    end

    it "appends callbacks" do
      join.should_receive(:update_resource_collections_cache!).once.with(Cacher)
      join.save
    end
  end

  describe "#update_resource_collections_cache!" do
    after :each do
      join # Create join object and raise reset cache procedure
    end

    it "works" do
      CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).once.with(Cacher, [cacher.id], :one)
      CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).once.with(Cacher, [cacher.id], :two)
      CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).once.with(Cacher, [cacher.id], :joins)
    end
  end
end
