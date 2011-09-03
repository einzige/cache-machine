require 'spec_helper'

describe CacheMachine do
  TARGET_TABLE_NAME = "cachers"
  HABTM_TABLE_NAME = "has_and_belongs_to_many_cacheables"
  HABTM_JOINS_TABLE_NAME = [TARGET_TABLE_NAME, HABTM_TABLE_NAME].join('_')
  HABTM_ASSOCIATION_NAME = HABTM_TABLE_NAME.singularize
  HM_TABLE_NAME = "has_many_cacheables"
  HMT_JOINS_TABLE_NAME = "joins"
  HMT_TABLE_NAME = "has_many_through_cacheables"
  HO_TABLE_NAME = "hs_one_cacheables"
  POLY_TABLE_NAME = "polymorphics"
  TARGET_ASSOCIATION_NAME = TARGET_TABLE_NAME.singularize
  HMT_ASSOCIATION_NAME = HMT_TABLE_NAME.singularize

  class TestMigration < ActiveRecord::Migration
    def self.up
      self.down
      create_table(HABTM_TABLE_NAME)
      create_table(HM_TABLE_NAME) { |t| t.references TARGET_ASSOCIATION_NAME }
      create_table(HMT_TABLE_NAME)
      create_table(HMT_JOINS_TABLE_NAME) { |t| [TARGET_ASSOCIATION_NAME, HMT_ASSOCIATION_NAME].each &t.method(:references) }
      create_table(POLY_TABLE_NAME) { |t| t.references(:polymorhicable); t.string(:polymorhicable_type) }
      create_table(TARGET_TABLE_NAME) { |t| t.string :name; t.integer(:parent_id) }
      create_table(HABTM_JOINS_TABLE_NAME, :id => false) { |t| [TARGET_ASSOCIATION_NAME, HABTM_ASSOCIATION_NAME].each &t.method(:references) }
    end

    def self.down
      drop_table POLY_TABLE_NAME if ActiveRecord::Base.connection.tables.include? POLY_TABLE_NAME
      drop_table TARGET_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(TARGET_TABLE_NAME)
      drop_table HABTM_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HABTM_TABLE_NAME)
      drop_table HM_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HM_TABLE_NAME)
      drop_table HMT_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HMT_TABLE_NAME)
      drop_table HO_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HO_TABLE_NAME)
      drop_table HMT_JOINS_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HMT_JOINS_TABLE_NAME)
      drop_table HABTM_JOINS_TABLE_NAME if ActiveRecord::Base.connection.tables.include?(HABTM_JOINS_TABLE_NAME)
    end
  end
  TestMigration.up

  class HasManyCacheable < ActiveRecord::Base
    set_table_name HM_TABLE_NAME
    belongs_to :cacher, :class_name => 'Cacher'
  end

  class HasManyThroughCacheable < ActiveRecord::Base
    set_table_name HMT_TABLE_NAME

    has_many :joins, :class_name => 'Join'
    has_many :cachers, :through => :joins, :class_name => 'Cacher'
  end

  class Join < ActiveRecord::Base
    set_table_name HMT_JOINS_TABLE_NAME

    belongs_to :cacher, :class_name => 'Cacher'
    belongs_to :has_many_through_cacheable, :class_name => 'HasManyThroughCacheable'
  end

  class HasAndBelongsToManyCacheable < ActiveRecord::Base
    set_table_name HABTM_TABLE_NAME
    has_and_belongs_to_many :cachers, :class_name => 'Cacher'
  end

  class Polymorphic < ActiveRecord::Base
    set_table_name POLY_TABLE_NAME
    belongs_to :polymorhicable, :polymorphic => true
  end

  class Cacher < ActiveRecord::Base
    set_table_name TARGET_TABLE_NAME

    acts_as_cache_machine_for :polymorphics,
                              :child_cachers,
                              :has_many_cacheables => :dependent_cache,
                              :has_many_through_cacheables => :dependent_cache,
                              :has_and_belongs_to_many_cacheables => :dependent_cache

    has_and_belongs_to_many :has_and_belongs_to_many_cacheables, :class_name => 'HasAndBelongsToManyCacheable'
    has_many :has_many_cacheables, :class_name => 'HasManyCacheable'
    has_many :joins, :class_name => 'Join'
    has_many :has_many_through_cacheables, :through => :joins, :class_name => 'HasManyThroughCacheable'
    has_many :polymorphics, :as => :polymorhicable
    has_many :child_cachers, :class_name => 'Cacher', :foreign_key => 'parent_id', :primary_key => 'id'

    def to_param; name end
  end

  subject { Cacher.create(:name => 'foo') }

  it "generates association cache keys" do
    subject.cache_key_of(:has_many_cacheables, :format => :ehtml).should eql("Cacher_foo_has_many_cacheables_ehtml_1")
  end

  it "stores association cache" do
    subject.fetch_cache_of(:has_many_cacheables) { 'cache' }
    cached_result = subject.fetch_cache_of(:has_many_cacheables) { 'fresh cache' }
    cached_result.should eql('cache')
  end

  describe "deletes cache" do

    context "of polymorphic associations" do
      it "works" do
        cached_result = subject.fetch_cache_of(:polymorphics) { 'cache' }
        subject.polymorphics.create
        cached_result = subject.fetch_cache_of(:polymorphics) { 'new cache' }

        cached_result.should eql('new cache')
      end
    end

    context "of paginated content" do
      before :each do
        subject.delete_cache_of :has_many_cacheables
      end

      it "works" do
        subject.fetch_cache_of(:has_many_cacheables, :page => 1) { 'page 1' }.should eql('page 1')
        subject.fetch_cache_of(:has_many_cacheables, :page => 2) { 'page 2' }.should eql('page 2')
        subject.delete_cache_of(:has_many_cacheables)
        subject.fetch_cache_of(:has_many_cacheables, :page => 1) { 'fresh page 1' }.should eql('fresh page 1')
        subject.fetch_cache_of(:has_many_cacheables, :page => 2) { 'fresh page 2' }.should eql('fresh page 2')
      end
    end

    context "of self-join association" do
      it "works" do
        subject.fetch_cache_of(:child_cachers) { 'cache' }
        child = Cacher.create(:parent_id => subject.id)
        cached_result = subject.fetch_cache_of(:child_cachers) { 'new cache' }

        cached_result.should eql('new cache')
      end
    end

    context "of any member on has_many" do
      before :each do
        @existing_entry = subject.has_many_cacheables.create
        @new_entry = HasManyCacheable.create
        subject.fetch_cache_of(:has_many_cacheables) { 'cache' }
      end

      after :each do
        cached_result = subject.fetch_cache_of(:has_many_cacheables) { 'fresh cache' }
        cached_result.should eql('fresh cache')
        subject.delete_cache_of(:has_many_cacheables)
      end

      it("works") { subject.delete_cache_of(:has_many_cacheables) }
      it("on update entry in collection") { @existing_entry.save }
      it("on add new entry in collection") { subject.has_many_cacheables << @new_entry }
      it("on destroy intem in collection") { subject.has_many_cacheables.destroy @existing_entry }
      it("on destroy intem") { HasManyCacheable.destroy @existing_entry }

      context "by chain" do
        it "works" do
          subject.fetch_cache_of(:dependent_cache) { 'cache' }
          subject.has_many_cacheables.create
          subject.fetch_cache_of(:dependent_cache) { 'fresh cache' }.should eql('fresh cache')
        end
      end
    end

    context "of any member on has_many :through" do
      before :each do
        @existing_entry = subject.has_many_through_cacheables.create
        @new_entry = HasManyThroughCacheable.create
        subject.fetch_cache_of(:has_many_through_cacheables) { 'cache' }
      end

      after :each do
        cached_result = subject.fetch_cache_of(:has_many_through_cacheables) { 'fresh cache' }
        cached_result.should eql('fresh cache')
        subject.delete_cache_of(:has_many_through_cacheables)
      end

      it("works") { subject.delete_cache_of(:has_many_through_cacheables) }
      it("on update entry in collection") { @existing_entry.save }
      it("on add new entry in collection") { subject.has_many_through_cacheables << @new_entry }
      it("on destroy intem in collection") { subject.has_many_through_cacheables.destroy @existing_entry }
      it("on destroy intem") { HasManyThroughCacheable.destroy @existing_entry }

      context "by chain" do
        it "works" do
          subject.fetch_cache_of(:dependent_cache) { 'cache' }
          subject.has_many_through_cacheables.create
          subject.fetch_cache_of(:dependent_cache) { 'fresh cache' }.should eql('fresh cache')
        end
      end
    end

    context "of any member on has_and_belongs_to_many" do
      before :each do
        @existing_entry = subject.has_and_belongs_to_many_cacheables.create
        @new_entry = HasAndBelongsToManyCacheable.create
        subject.fetch_cache_of(:has_and_belongs_to_many_cacheables) { 'cache' }
      end

      after :each do
        cached_result = subject.fetch_cache_of(:has_and_belongs_to_many_cacheables) { 'fresh cache' }
        cached_result.should eql('fresh cache')
        subject.delete_cache_of(:has_and_belongs_to_many_cacheables)
      end

      it("works") { subject.delete_cache_of(:has_and_belongs_to_many_cacheables) }
      it("on update entry in collection") { @existing_entry.save }
      it("on add new entry in collection") { subject.has_and_belongs_to_many_cacheables << @new_entry }
      it("on destroy intem in collection") { subject.has_and_belongs_to_many_cacheables.destroy @existing_entry }
      it("on destroy intem") { HasAndBelongsToManyCacheable.destroy @existing_entry }

      context "by chain" do
        it "works" do
          subject.fetch_cache_of(:dependent_cache) { 'cache' }
          subject.has_and_belongs_to_many_cacheables.create
          subject.fetch_cache_of(:dependent_cache) { 'fresh cache' }.should eql('fresh cache')
        end
      end
    end
  end
end
