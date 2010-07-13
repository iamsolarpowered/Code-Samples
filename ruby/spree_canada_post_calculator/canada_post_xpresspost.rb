class Calculator::CanadaPostXpresspost < Calculator::CanadaPostBase

  def self.description
    "Canada Post Xpresspost"
  end
  
  def product_names
    ['Xpresspost', 'Xpresspost USA', 'Expedited']
  end
end
