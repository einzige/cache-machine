TARGET_TABLE_NAME       = "cachers"
HABTM_TABLE_NAME        = "has_and_belongs_to_many_cacheables"
HABTM_JOINS_TABLE_NAME  = [TARGET_TABLE_NAME, HABTM_TABLE_NAME].join('_')
HABTM_ASSOCIATION_NAME  = HABTM_TABLE_NAME.singularize
HM_TABLE_NAME           = "has_many_cacheables"
HMT_JOINS_TABLE_NAME    = "joins"
HMT_TABLE_NAME          = "has_many_through_cacheables"
HO_TABLE_NAME           = "hs_one_cacheables"
POLY_TABLE_NAME         = "polymorphics"
TARGET_ASSOCIATION_NAME = TARGET_TABLE_NAME.singularize
HMT_ASSOCIATION_NAME    = HMT_TABLE_NAME.singularize

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
    drop_table POLY_TABLE_NAME        if ActiveRecord::Base.connection.tables.include?(POLY_TABLE_NAME)
    drop_table TARGET_TABLE_NAME      if ActiveRecord::Base.connection.tables.include?(TARGET_TABLE_NAME)
    drop_table HABTM_TABLE_NAME       if ActiveRecord::Base.connection.tables.include?(HABTM_TABLE_NAME)
    drop_table HM_TABLE_NAME          if ActiveRecord::Base.connection.tables.include?(HM_TABLE_NAME)
    drop_table HMT_TABLE_NAME         if ActiveRecord::Base.connection.tables.include?(HMT_TABLE_NAME)
    drop_table HO_TABLE_NAME          if ActiveRecord::Base.connection.tables.include?(HO_TABLE_NAME)
    drop_table HMT_JOINS_TABLE_NAME   if ActiveRecord::Base.connection.tables.include?(HMT_JOINS_TABLE_NAME)
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

  scope :test_scope, joins(:cacher).where(:cachers => { :name => %w{one two} })

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
  cattr_accessor :stamp
  set_table_name TARGET_TABLE_NAME

  scope :test_scope, where(:name => %w{one two})

  has_and_belongs_to_many :has_and_belongs_to_many_cacheables, :class_name => 'HasAndBelongsToManyCacheable'
  has_many :has_many_cacheables, :class_name => 'HasManyCacheable'
  has_many :joins, :class_name => 'Join'
  has_many :has_many_through_cacheables, :through => :joins, :class_name => 'HasManyThroughCacheable'
  has_many :polymorphics, :as => :polymorhicable
  has_many :child_cachers, :class_name => 'Cacher', :foreign_key => 'parent_id', :primary_key => 'id'

  def to_param; name end
end