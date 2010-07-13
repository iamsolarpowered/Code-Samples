class Location < ActiveRecord::Base
  belongs_to :location_type
  has_many :clinic_relationships, :foreign_key => 'pharmacy_id', :class_name => 'LocationRelationship'
  has_many :partner_clinics, :through => :clinic_relationships, :source => :clinic
  has_many :pharmacy_relationships, :foreign_key => 'clinic_id', :class_name => 'LocationRelationship'
  has_many :partner_pharmacies, :through => :pharmacy_relationships, :source => :pharmacy
  
  validates_presence_of :name, :location_type
  validates_presence_of :address_1, :city, :state
  
  default_scope :order => 'location_type_id, zipcode'
  
  named_scope :clinics, :joins => :location_type, :conditions => 'location_types.name == "Clinic"'
  named_scope :pharmacies, :joins => :location_type, :conditions => 'location_types.name == "Pharmacy"'
  
  before_save :geocode
  
  def self.unconnected
    locations = all.delete_if {|l| !l.unconnected? }
  end
  
  def geocode
    if res = Geokit::Geocoders::GoogleGeocoder.geocode(formatted_address(false))
      self.lat = res.lat
      self.lng = res.lng
    end
  end
  
  def icon_uri
    "/images/map/#{location_type_name.underscore}.png"
  end
  
  def info_window_content
    html = "<h2>#{name}</h2>"
    html += "<p class=\"address\">#{formatted_address}</p>"
    html += "<p class=\"details\">#{formatted_details}</p>"
    html += "<p class=\"related_locations\">#{related_locations_map_links}</p>"
    html
  end
  
  def location_type_name
    location_type && location_type.name
  end
  
  def clinic?
    location_type_name == 'Clinic'
  end
  
  def pharmacy?
    location_type_name == 'Pharmacy'
  end
  
  def unconnected?
    if clinic?
      LocationRelationship.find_all_by_clinic_id(self).count == 0
    elsif pharmacy?
      LocationRelationship.find_all_by_pharmacy_id(self).count == 0
    end
  end
  
  def formatted_address(breaks=true)
    text = "#{address_1}#{breaks ? '<br />' : ', ' }"
    text += "#{address_2}#{breaks ? '<br />' : ', ' }" unless address_2.blank?
    text += "#{city}, #{state} #{zipcode}"
    text
  end
  
  def formatted_details
    helpers.auto_link(helpers.textilize(details), :all, :target => '_blank')
  end
  
  def map_link
    "<a href=\"#\" onclick=\"zoomToLocation(#{id})\">#{name}</a>"
  end
  
  def related_locations
    return @related_locations if defined?(@related_locations)
    if location_type_name == 'Clinic'
      @related_locations = partner_pharmacies
    elsif location_type_name == 'Pharmacy'
      @related_locations = partner_clinics
    end
  end
  
  def related_locations_label
    text = ''
    text += 'Partner Pharmacy' if clinic?
    text += 'Partner Clinic' if pharmacy?
    related_locations.length == 1 ? text : text.pluralize
  end
  
  def related_locations_map_links
    text = ''
    unless related_locations.blank?
      text += "#{related_locations_label}: "
      text += related_locations.map(&:map_link).join(', ')
    end
    text
  end
  
  private
  
  def helpers
    ActionController::Base.helpers
  end
end
