require 'httparty'
require 'nokogiri'
require 'byebug'
require 'watir'
require 'webdrivers'

# class BtcScraper

	# def initialize
	LOCAL_BITCOINS_COP_QUICK_SELL_URL = "https://localbitcoins.com/instant-bitcoins/?action=sell&country_code=CO&amount=&currency=COP&place_country=CO&online_provider=SPECIFIC_BANK&find-offers=Search"
	LOCAL_BITCOINS_USD_QUICK_BUY_URL = "https://localbitcoins.com/instant-bitcoins/?action=buy&country_code=US&amount=&currency=USD&place_country=US&online_provider=ZELLE&find-offers=Search"
	SETFX_USD_TRM_URL = "http://www.set-fx.com/index.html"
	def scrape_page(url)
		scrape = Nokogiri::HTML(HTTParty.get(url))
	end
	@TRM = 0
	def get_usd_trm
		p 'calculando trm'
		page = scrape_page(SETFX_USD_TRM_URL)
		browser = Watir::Browser.start('http://www.set-fx.com/index.html')
		Watir::Wait.until(timeout: 300) {browser.element(css: "#barraTuristaPromedio").text.include? '$'}
		trm = browser.element(css: "#barraTuristaPromedio").text[2..].delete(',').to_f
		p 'trm calculada'
	end
		
	# end
	


	def get_quick_sell_offers
    page = scrape_page(LOCAL_BITCOINS_COP_QUICK_SELL_URL)
    ofertas = page.css('td.column-price').map{|o| o.children.text.strip[0...-4].delete(',').to_f/@TRM}
  end
p
  def get_quick_buy_offers
    page = scrape_page(LOCAL_BITCOINS_USD_QUICK_BUY_URL)
    ofertas = page.css('td.column-price').map{|o| o.children.text.strip[0...-4].delete(',').to_f}
	end
	
	def calculate
		@TRM = get_usd_trm
		cop_offers = get_quick_sell_offers
		usd_offers = get_quick_buy_offers
		byebug
	end
	
	# private 

# end

calculate