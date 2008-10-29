class GeocoderQuery < ActiveRecord::Base
  
  # Moved from geocode.rb
  validates_uniqueness_of :query
  
  belongs_to :geocode
  
end
