require 'spec_helper'
require 'fixtures'

describe CacheMachine do
  subject { Cacher.create(:name => 'foo') }

  describe "#cache_key_of" do
    it "generates association cache keys" do
      subject.cache_key_of(:anything).should eql("Cacher_foo_anything_1")
      subject.cache_key_of(:anything, :format => :ehtml).should eql("Cacher_foo_anything_ehtml_1")
      subject.cache_key_of(:anything, :page => 2).should eql("Cacher_foo_anything_2")
      subject.cache_key_of(:anything, :format => :ehtml, :page => 2).should eql("Cacher_foo_anything_ehtml_2")
    end
  end

  describe "#fetch_cache_of" do
    it "stores association cache" do
      subject.fetch_cache_of(:has_many_cacheables) { 'cache' }
      subject.fetch_cache_of(:has_many_cacheables).should == 'cache'
    end

    context "timestamps" do
      it "works with timestamps" do
        subject.should_receive(:cache_key_of).with(:anything, hash_including(:timestamp => :dynamic_timestamp)).and_return "returned_stamp"
        Rails.cache.should_receive(:fetch).with("Content#returned_stamp", :expires_in => nil).once
        subject.fetch_cache_of(:anything, :timestamp => :dynamic_timestamp)
      end

      it "calls for instance methods" do
        subject.should_receive(:execute_timestamp).once
        subject.fetch_cache_of(:anything, :timestamp => :dynamic_timestamp)
      end
    end
  end

  context "resets cache" do
    describe "#delete_all_caches" do
      it "removes all caches using map" do
        subject.should_receive(:delete_cache_of).with(:polymorphics).once
        subject.should_receive(:delete_cache_of).with(:child_cachers).once
        subject.should_receive(:delete_cache_of).with(:has_many_cacheables).once
        subject.should_receive(:delete_cache_of).with(:dependent_cache).once
        subject.should_receive(:delete_cache_of).with(:has_many_through_cacheables).once
        subject.should_receive(:delete_cache_of).with(:has_and_belongs_to_many_cacheables).once
        subject.delete_all_caches
      end
    end

    describe "#delete_cache_of" do
      it "resets cache" do
        subject.fetch_cache_of(:anything) { 'cache' }
        subject.delete_cache_of :anything
        subject.fetch_cache_of(:anything).should be_nil
      end

      it "resets cache by map" do
        subject.fetch_cache_of(:dependent_cache) { 'cache' }
        subject.delete_cache_of :has_many_cacheables
        subject.fetch_cache_of(:dependent_cache).should be_nil
      end

      context "callbacks" do
        context "on polymorphic associations" do
          it "resets cache on add new item to associated collection" do
            subject.fetch_cache_of(:polymorphics) { 'cache' }
            subject.polymorphics.create
            subject.fetch_cache_of(:polymorphics).should be_nil
          end
        end

        context "on self-join associations" do
          it "resets cache on add new item to associated collection" do
            subject.fetch_cache_of(:child_cachers) { 'cache' }
            Cacher.create(:parent_id => subject.id)
            subject.fetch_cache_of(:child_cachers).should be_nil
          end
        end

        context "on has_many associations" do
          let(:new_entry) { HasManyCacheable.create }

          before :each do
            @existing_entry = subject.has_many_cacheables.create
            subject.fetch_cache_of(:has_many_cacheables) { 'cache' }
          end

          after :each do
            subject.fetch_cache_of(:has_many_cacheables).should be_nil
            subject.delete_cache_of(:has_many_cacheables)
          end

          it("on update entry in collection")  { @existing_entry.save }
          it("on add new entry in collection") { subject.has_many_cacheables << new_entry }
          it("on destroy intem in collection") { subject.has_many_cacheables.destroy @existing_entry }
          it("on destroy intem")               { HasManyCacheable.destroy @existing_entry }
        end
      end

      context "has_many :through associations" do
        let(:new_entry) { HasManyThroughCacheable.create }

        before :each do
          @existing_entry = subject.has_many_through_cacheables.create
          subject.fetch_cache_of(:has_many_through_cacheables) { 'cache' }
        end

        after :each do
          subject.fetch_cache_of(:has_many_through_cacheables).should be_nil
          subject.delete_cache_of(:has_many_through_cacheables)
        end

        it("on update entry in collection")  { @existing_entry.save }
        it("on add new entry in collection") { subject.has_many_through_cacheables << new_entry }
        it("on destroy intem in collection") { subject.has_many_through_cacheables.destroy @existing_entry }
        it("on destroy intem")               { HasManyThroughCacheable.destroy @existing_entry }
      end

      context "has_and_belongs_to_many associations" do
        let(:new_entry) { HasAndBelongsToManyCacheable.create }
        before :each do
          @existing_entry = subject.has_and_belongs_to_many_cacheables.create
          subject.fetch_cache_of(:has_and_belongs_to_many_cacheables) { 'cache' }
        end

        after :each do
          subject.fetch_cache_of(:has_and_belongs_to_many_cacheables).should be_nil
          subject.delete_cache_of(:has_and_belongs_to_many_cacheables)
        end

        it("on update entry in collection")  { @existing_entry.save }
        it("on add new entry in collection") { subject.has_and_belongs_to_many_cacheables << new_entry }
        it("on destroy intem in collection") { subject.has_and_belongs_to_many_cacheables.destroy @existing_entry }
        it("on destroy intem")               { HasAndBelongsToManyCacheable.destroy @existing_entry }
      end

      context "paginated content" do
        it "works" do
          subject.delete_cache_of :has_many_cacheables
          subject.fetch_cache_of(:has_many_cacheables, :page => 1) { 'page 1' }.should eql('page 1')
          subject.fetch_cache_of(:has_many_cacheables, :page => 2) { 'page 2' }.should eql('page 2')

          subject.delete_cache_of(:has_many_cacheables)

          subject.fetch_cache_of(:has_many_cacheables, :page => 1).should be_nil
          subject.fetch_cache_of(:has_many_cacheables, :page => 2).should be_nil
        end
      end
    end
  end
end
