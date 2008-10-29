class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table "geocodes" do |t|
      t.column "latitude", :decimal, :precision => 15, :scale => 12
      t.column "longitude", :decimal, :precision => 15, :scale => 12
      t.column "street", :string
      t.column "locality", :string
      t.column "region", :string
      t.column "postal_code", :string
      t.column "country", :string
    end

    add_index "geocodes", ["longitude"], :name => "geocodes_longitude_index"
    add_index "geocodes", ["latitude"], :name => "geocodes_latitude_index"

    create_table "geocodings" do |t|
      t.column "geocodable_id", :integer
      t.column "geocode_id", :integer
      t.column "geocodable_type", :string
    end

    add_index "geocodings", ["geocodable_type"], :name => "geocodings_geocodable_type_index"
    add_index "geocodings", ["geocode_id"], :name => "geocodings_geocode_id_index"
    add_index "geocodings", ["geocodable_id"], :name => "geocodings_geocodable_id_index"
    
    create_table "geocoder_queries" do |t|
      t.column "query", :string
      t.column "geocode_id", :integer
      t.timestamps
    end
    
    add_index "geocoder_queries", ["query"], :name => "geocoder_queries_query_index", :unique => true
  end

  def self.down
    drop_table  :geocodes
    drop_table  :geocodings
    drop_table  :geocoder_queries
  end
end
