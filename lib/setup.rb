require 'json'
require '/home/fram/projects/prestashop-automation/lib/prestashop-automation.rb'

def arrify val
	if val.is_a? Array
		val
	else
		[val]
	end
end

@cleanup = cleanup = []

RSpec.configure do |c|
	c.after :all do
		cleanup.map(&:call)
	end
end

def for_each_version options={}, &block
	shops = JSON.parse File.read('config/shops.json'), :symbolize_names => true

	threads = []
	shops.each_pair do |shop_name, data|

		should_run = true

		if options[:only] and not arrify(options[:only]).include? shop_name.to_s
			should_run = false
		end

		if options[:except] and arrify(options[:except]).include? shop_name.to_s
			should_run = false
		end

		if should_run
			shop = PrestaShopAutomation::PrestaShop.new(data)

			dump = shop.save

			yield(shop)

			@cleanup << lambda do
				shop.restore dump
			end
		end
	end
end
