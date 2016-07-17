require 'nokogiri'
require 'watir'
require 'mysql'


connection = Mysql.new('localhost','root','password','ipl') #DataBase connection details
browser    = Watir::Browser.new(:phantomjs)
year_array = (2008..2016).to_a
matches    = (1..76).to_a
year_array.each do |year|
    matches.each do |match_number|
        
        begin
            browser.goto("http://www.iplt20.com/match/#{year}/#{match_number}")
            #browser.goto("http://www.iplt20.com/match/2015/18")
            browser.link(:text,"Scorecard").when_present.click
            document = Nokogiri::HTML(browser.html)
            
            first_innings_end  = 0
            second_innings_end = 0
            first_innings_end  = document.css('div[class="remainingBatsmen"]')[0].css('a[class="player-popup-link"]').length
            
            begin # rescue block to ensure its not going to last rescue but contine with populating first innings data
             second_innings_end = document.css('div[class="remainingBatsmen"]')[1].css('a[class="player-popup-link"]').length
             rescue
              puts "----No Second Innings Played----"
            end
            
            innings = 1
            total_innings_payed = first_innings_end + second_innings_end #to take jus the first two innings batting records excluding the super over
            total_innings_payed.times do |i|
             if i == first_innings_end #index of array starts from zero
                 innings = 2
             end
             if innings == 1
                 team=document.css('div[class="teamHeader"]')[0].text.split(" Innings")[0].strip
             else
                 team=document.css('div[class="teamHeader"]')[1].text.split(" Innings")[0].strip
             end
             batsmen_name   = document.css('div[class="remainingBatsmen"]').css('a[class="player-popup-link"]')[i].text
             match_datum_id = ((year*100) + match_number) 
             #puts "#{batsmen_name} #{dismissal} #{runs} #{balls_faced} #{strike_rate} #{fours} #{sixes} #{innings}"
            
             puts "#{batsmen_name} #{innings}=--#{year} #{match_number} #{team} #{match_datum_id}"
              insert_data = "CALL insert_batting_data(\"#{batsmen_name}\",#{year},#{match_number},#{innings},#{match_datum_id},\"#{team}\")"
              connection.query(insert_data)
            end
            
        
            rescue NoMethodError
            print "continue with next"
        end
    end
end
connection.close