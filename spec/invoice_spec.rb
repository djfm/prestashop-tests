require 'setup'

def test_invoice ps, scenario, options={}
	ps.login_to_back_office
	ps.set_friendly_urls false
	ps.set_order_process_type scenario['meta']['order_process'].to_sym

	if scenario["discounts"]
		scenario["discounts"].each_pair do |name, amount|
			ps.create_cart_rule :name=> name, :amount => amount
		end
	end

	if scenario["gift_wrapping"]
		ps.set_gift_wrapping_option true,
			:price => scenario["gift_wrapping"]["price"],
			:tax_group_id => scenario["gift_wrapping"]["vat"] ? get_or_create_tax_group_id_for_rate(scenario["gift_wrapping"]["vat"]) : nil,
			:recycling_option => false
	else
		ps.set_gift_wrapping_option false
	end

	carrier_name = ps.create_carrier({
		:name => scenario['carrier']['name'],
		:with_handling_fees => scenario['carrier']['with_handling_fees'],
		:free_shipping => scenario['carrier']['shipping_fees'] == 0,
		:ranges => [{:from_included => 0, :to_excluded => 1000, :prices => {0 => scenario['carrier']['shipping_fees']}}],
		:tax_group_id => scenario['carrier']['vat'] ? get_or_create_tax_group_id_for_rate(scenario['carrier']['vat']) : nil
	})

	products = []
	scenario['products'].each_pair do |name, data|
		id = ps.create_product({
			:name => name,
			:price => data['price'],
			:tax_group_id => ps.create_tax_group_from_rate(data['vat']),
			:specific_price => data['specific_price']
		})
		products << {id: id, quantity: data['quantity']}

		if data["discount"]
			ps.create_cart_rule({
				:product_id => id,
				:amount => data["discount"],
				:free_shipping => false,
				:name => "#{name} with (#{data['discount']}) discount"
			})
		end
	end

	ps.login_to_front_office
	ps.add_products_to_cart products

	order_id = if scenario['meta']['order_process'] == 'five_steps'
		ps.order_current_cart_5_steps :carrier => carrier_name, :gift_wrapping => scenario["gift_wrapping"]
	else
		ps.order_current_cart_opc :carrier => carrier_name, :gift_wrapping => scenario["gift_wrapping"]
	end

	ps.goto_back_office
	invoice = ps.validate_order :id => order_id, :dump_pdf_to => options[:dump_pdf_to], :get_invoice_json => true

	if scenario['expect']['invoice']
		if expected_total = scenario['expect']['invoice']['total']
			actual_total = invoice['order']
			mapping = {
				'to_pay_tax_included' => 'total_paid_tax_incl',
				'to_pay_tax_excluded' => 'total_paid_tax_excl',
				'products_tax_included' => 'total_products_wt',
				'products_tax_excluded' => 'total_products',
				'shipping_tax_included' => 'total_shipping_tax_incl',
				'shipping_tax_excluded' => 'total_shipping_tax_excl',
				'discounts_tax_included' => 'total_discounts_tax_incl',
				'discounts_tax_excluded' => 'total_discounts_tax_excl',
				'wrapping_tax_included' => 'total_wrapping_tax_incl',
				'wrapping_tax_excluded' => 'total_wrapping_tax_excl'
			}
			expected_total.each_pair do |key, value_expected|
				expect(value_expected.to_s).to eq actual_total[mapping[key]].to_s
			end
		end
	end
end

Dir.glob File.join(File.dirname(__FILE__), 'invoice/*.json') do |path|
	data = JSON.parse File.read(path)
	for_each_version({
		:except => (data['spec'] and data['spec']['except']),
		:only => (data['spec'] and data['spec']['only'])
	}) do |shop|
		shop.save
		describe ((data['spec'] and data['spec']['name']) or path) do
			it 'should compute correctly' do
				test_invoice shop, data
			end
		end
		shop.restore
	end
end
