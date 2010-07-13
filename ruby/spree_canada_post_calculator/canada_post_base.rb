require 'net/http'
require 'uri'
require 'hpricot'

class Calculator::CanadaPostBase < Calculator

  SETTINGS = YAML.load_file(File.join(File.dirname(__FILE__), '../../../config/canada_post_settings.yml'))
  
  def self.available?(object)
    true
  end

  def self.register
    super
    Coupon.register_calculator(self)
    ShippingMethod.register_calculator(self)
    ShippingRate.register_calculator(self)
  end
  
  def compute(object)
    base = object if object.is_a?(Order)
    base = object.order if object.is_a?(LineItem)
    base = object.first.order if object.is_a?(Array)
    shipment = base.shipments.first
    get_rate shipment
  end
  
  def get_rate(shipment)
    @shipment = shipment
    @settings = SETTINGS
    
    set_box_size
    
    rate_with_handling
  end
  
  def parsed_response
    @parsed_response ||= Hpricot::XML(response.body)
  end
  
  def products
    @products = {}
    (parsed_response/:product).each do |p|
      name = (p/:name).inner_html.to_s
      price = (p/:rate).inner_html.to_f
      @products[name] = price
    end
    @products
  end
  
  def rate
    product = nil
    product_names.each {|name| product ||= products[name] }
    if product
      product.to_f
    else
      @settings['default_rate'].to_f
    end
  end
  
  def rate_with_handling
    rate + @settings['handling'].to_f
  end
  
  def request
    r = Net::HTTP::Post.new(@settings['url'])
    r.body = request_xml
    r
  end
  
  def response
    @response ||= Net::HTTP.start(url.host, url.port) {|http| http.request(request) }
  end
  
  def set_box_size
    @shipment.update_attributes(
      :box_width => (parsed_response/'box'/'width').inner_html.to_f,
      :box_length => (parsed_response/'box'/'width').inner_html.to_f,
      :box_height => (parsed_response/'box'/'width').inner_html.to_f
    )
  end
  
  def url
    URI.parse(@settings['url'])
  end
  
  private

    def request_xml
      @request_xml = <<EOF
<?xml version="1.0" ?>
<eparcel>
  <language> #{@settings['language']} </language>
  <ratesAndServicesRequest>
    <merchantCPCID> #{@settings['merchant_id']} </merchantCPCID>
    <fromPostalCode> #{@settings['from_postal_code']} </fromPostalCode>
    <turnAroundTime> #{@settings['turn_around_time']} </turnAroundTime>
    
    <lineItems>
      #{line_items_xml}
    </lineItems>

    <city> #{@shipment.address.city} </city>
    <provOrState> #{@shipment.address.state.name} </provOrState>
    <country> #{@shipment.address.country.iso} </country>
    <postalCode> #{@shipment.address.zipcode} </postalCode>
  </ratesAndServicesRequest>
</eparcel>
EOF
    end
    
    def line_items_xml
      xml = ''
      @shipment.line_items.each do |item|
        xml += <<EOF
<item>
    <quantity> #{item.quantity} </quantity>
    <weight> #{item.variant.weight.to_f} </weight>
    <length> #{item.variant.depth.to_f} </length>
    <width> #{item.variant.width.to_f} </width>
    <height> #{item.variant.height.to_f} </height>
    <description> #{item.variant.name} </description>
</item>
EOF
      end
      xml
    end
end
