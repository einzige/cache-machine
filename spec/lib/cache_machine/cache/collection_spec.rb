require 'spec_helper'

describe CacheMachine::Cache::Collection do

  let(:cacher) { cacher = Cacher.create }
  let(:join)   { cacher.joins.create    }
  let(:hm)     { cacher.has_many_cacheables.create }
  let(:hmt)    { HasManyThroughCacheable.create(:cachers => [cacher]) }
  let(:phm)    { cacher.polymorphics.create }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher do
        collection :joins do
          member :one
          member :two
        end
        collection :has_many_through_cacheables
        collection :has_many_cacheables
        collection :polymorphics
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

    context "on has one relation" do
      after(:each) { join }

      it "works" do
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :one)
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :two)
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :joins)
      end
    end

    context "on has many relation" do
      after(:each) { hm }

      it "works" do
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :has_many_cacheables)
      end
    end

    context "on has many through relation" do
      before(:each) { hmt }
      after(:each) { hmt.save }

      it "works" do
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :has_many_through_cacheables)
      end
    end

    context "on polymorphic relation" do
      before(:each) { phm }
      after(:each) { phm.save }

      it "works" do
        CacheMachine::Cache::Map.should_receive(:reset_cache_on_map).with(Cacher, [cacher.id], :polymorphics)
      end
    end
  end
end
