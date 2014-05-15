require 'setup'

configurations = {
	'bn' => %w(bd fr),
	'br' => %w(br de),
	'ca' => %w(es fr),
	'cs' => %w(cz fr),
	'de' => %w(de it),
	'en' => %w(us pt),
	'es' => %w(es ru),
	'fa' => %w(ir nl),
	'fr' => %w(fr it),
	'hu' => %w(hu de),
	'id' => %w(id cz),
	'it' => %w(it hu),
	'mk' => %w(mk ru),
	'nl' => %w(nl de),
	'no' => %w(no ro),
	'pl' => %w(pl ru),
	'ru' => %w(ru fr),
	'sr' => %w(rs it),
	'tr' => %w(tr de),
	'tw' => %w(tw cn),
	'zh' => %w(cn tw)
}

for_each_version :only => '1.6-git' do |shop|
	describe 'Installation of PrestaShop' do
		configurations.each_pair do |language, countries|
			countries.each do |country|
				it "should succeed with country '#{country}' and language '#{language}'" do
					shop.clear_cookies
					shop.drop_database
					shop.install :country => country, :language => language
				end
			end
		end
	end
end
