require 'nokogiri'
require 'watir'
require 'mysql'


connection = Mysql.new('localhost','root','password','ipl_dummy_db') #DataBase connection details
browser    = Watir::Browser.new(:phantomjs)
year_array = (2008..2016).to_a
matches    = (1..75).to_a
year_array.each do |year|
    matches.each do |match_number|
        
        begin
            browser.goto("http://www.iplt20.com/match/#{year}/#{match_number}")
            #browser.goto("http://www.iplt20.com/match/2015/18")
            browser.link(:text,"Scorecard").when_present.click

            document = Nokogiri::HTML(browser.html)
            document.css('span[class="dismissalSmall"]').remove #Extra dismissal span present with batsmen name
            first_innings_end  = 0
            second_innings_end = 0
            first_innings_end  = document.css('table[class="batsmen"]')[0].css('tr[class="batsmanInns player-popup-link"]').length
            
            begin # rescue block to ensure its not going to last rescue but contine with populating first innings data
             second_innings_end = document.css('table[class="batsmen"]')[1].css('tr[class="batsmanInns player-popup-link"]').length
             rescue
              puts "----No Second Innings Played----"
            end
            
            innings = 1
            total_innings_payed = first_innings_end + second_innings_end #to take jus the first two innings batting records excluding the super over
            total_innings_payed.times do |i|
             if i == first_innings_end
                 innings = 2
             end
             batsmen_name = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="player"]').text
             dismissal    = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="dismissal"]').text
             runs         = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="runs"]').text
             balls_faced  = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="balls"]').text
             strike_rate  = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="strikeRate"]').text
             fours        = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="fours"]').text
             sixes        = document.css('table[class="batsmen"]').css('tr[class="batsmanInns player-popup-link"]')[i].css('td[class="sixes"]').text
            
             #puts "#{batsmen_name} #{dismissal} #{runs} #{balls_faced} #{strike_rate} #{fours} #{sixes} #{innings}"
             
             puts "#{batsmen_name} #{dismissal} #{runs} #{balls_faced} #{strike_rate} #{fours} #{sixes} #{innings}=--#{year} #{match_number}"
             insert_data = "CALL insert_batting_data(\"#{batsmen_name}\",\"#{dismissal}\",#{runs},#{balls_faced},#{strike_rate},#{fours},
                            #{sixes},#{year},#{match_number},#{innings})"
             connection.query(insert_data)
            end
            
        
            rescue NoMethodError
            print "continue with next"
        end
    end
end
connection.close