require 'nokogiri'
require 'watir'
require 'mysql'

connection = Mysql.new('localhost','root','password','ipl_dummy_db')
browser    = Watir::Browser.new(:phantomjs)
year_array = (2008..2016)
matches    = (1..75).to_a
year_array.each do |year|
    matches.each do |match_number|
        begin
            browser.goto("http://www.iplt20.com/match/#{year}/#{match_number}")
            browser.link(:text,"Scorecard").when_present.click
            
            document = Nokogiri::HTML(browser.html)
            id = (year*100) + match_number 
            puts "#{id}"
            first_batting_team  = document.css('div[class="teamHeader"]')[0].text.split(" Innings")[0].strip
            second_batting_team = document.css('div[class="teamHeader"]')[1].text.split(" Innings")[0].strip
            
            puts "First:#{first_batting_team} Second:#{second_batting_team}"
            
            insert_data = "CALL insert_innings_data(#{id},\"#{first_batting_team}\",\"#{second_batting_team}\")"
            connection.query(insert_data)
            
            rescue NoMethodError
            print "continue with next"
            
            
        end
        
    end
    
end
