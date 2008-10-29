class Geocode < ActiveRecord::Base
  include Comparable

  has_many :geocodings, :dependent => :destroy
  has_many :geocoder_queries, :dependent => :destroy
  
  cattr_accessor :geocoder
  
  def distance_to(destination, units = :miles, formula = :haversine)
    if destination && destination.latitude && destination.longitude
      Graticule::Distance.const_get(formula.to_s.camelize).distance(self, destination, units)
    end
  end

  def geocoded?
    !latitude.blank? && !longitude.blank?
  end
  
  def self.find_or_create_by_query(query)
    find_by_query(query) || create_by_query(query)
  end
  
  def self.create_by_query(query)
    location = geocoder.locate(query)
    # Find geocodes with this location that already exist
    geocodes = find(:all, :conditions => {:latitude => location.latitude, :longitude => location.longitude, 
      :street => location.street, :locality => location.locality, :region => location.region,
      :postal_code => location.postal_code, :country => location.country})
    geocoder_query = GeocoderQuery.new(:query => query)
    if geocodes.size == 0
      # No existing geocodes
      create location.attributes.merge(:geocoder_queries => [geocoder_query])
    elsif geocodes.size != 1
      # Too many geocodes with this location, should only be one geocode record per location.
      raise RuntimeError.new("There is more than one geocode with the same location: #{location}.")
    else
      # A single existing geocode at this location, create the geocoder query and associate with the geocode.
      geocodes[0].geocoder_queries << geocoder_query
    end
  end
  
  def self.find_or_create_by_location(location)
    find_by_query(location.to_s) || create_from_location(location)
  end
  
  def self.create_from_location(location)
    create geocoder.locate(location).attributes.merge(:query => location.to_s)
  rescue
    nil
  end
  
  def geocoded
    @geocoded ||= geocodings.collect { |geocoding| geocoding.geocodable }
  end
  
  def on(geocodable)
    geocodings.create :geocodable => geocodable
  end
  
  def <=>(comparison_object)
    self.to_s <=> comparison_object.to_s
  end

  # Note this may return values to the opposite way you were expecting!
  def coordinates
    "#{longitude},#{latitude}"
  end

  def to_s
    coordinates
  end
  
  # Create a Graticule::Location
  def to_location
    returning Graticule::Location.new do |location|
      [:street, :locality, :region, :postal_code, :country].each do |attr|
        location.send "#{attr}=", send(attr)
      end
    end
  end
  
  # Provide a find_by_query method that used to be created by rails for the Geocode model when it originally had a query column,
  # however, the query column was moved to a new table, geocoder_queries, to prevent duplication of geocoder data in the geocodes table.
  # This method returns a Geocode instance or nil if it cannot be found.
  def self.find_by_query(query)
    geocoder_query = GeocoderQuery.find_by_query(query)
    if (geocoder_query)
      return geocoder_query.geocode
    end
    return nil
  end

end