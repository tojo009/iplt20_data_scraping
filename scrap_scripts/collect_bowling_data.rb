require 'nokogiri'
require 'watir'
require 'mysql'

connection = Mysql.new("localhost","root","password","ipl_dummy_db")
browser    = Watir::Browser.new(:phantomjs)
year_array = (2008..2016)
matches    = (1..76)

year_array.each do|year|
    matches.each do|match_number|
        begin
            browser.goto("http://www.iplt20.com/match/#{year}/#{match_number}")
            #browser.goto("http://www.iplt20.com/match/2012/29")
            browser.link(text:"Scorecard").when_present.click
            
            document = Nokogiri::HTML(browser.html)
            
            first_innings_end  = 0
            second_innings_end = 0
            
            first_innings_end  = document.css('table[class="bowlers"]')[0].css('tr[class="player-popup-link"]').length
            begin # rescue block to ensure its not going to last rescue but contine with populating first innings data
             second_innings_end = document.css('table[class="bowlers"]')[1].css('tr[class="player-popup-link"]').length
            rescue
              puts "----No Second Innigs Played----"
            end
            
            innings = 1
            total_innings_payed = first_innings_end + second_innings_end #to take jus the first two innings batting records excluding the super over
            total_innings_payed.times do |i|
             if i == first_innings_end
                 innings = 2
             end
             
             bowler_name = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td[class="player"]').text
             overs       = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td')[2].text
             runs_given  = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td')[3].text
             wickets     = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td')[4].text
             economy     = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td[class="econ"]').text
             dot_balls   = document.css('table[class="bowlers"]').css('tr[class="player-popup-link"]')[i].css('td[class="dots"]').text
             if economy.eql?("-")
                 economy = 0   #zero economy rate
             end
             puts ("#{bowler_name} #{overs} #{runs_given} #{wickets} #{economy} #{dot_balls} #{innings} #{year} #{match_number}")
             insert_data = "CALL insert_bowling_data(\"#{bowler_name}\",#{overs},#{runs_given},#{wickets},#{economy},
                            #{dot_balls},#{innings},#{match_number},#{year})"
             connection.query(insert_data)
             
            end
        rescue NoMethodError
            print "continue next -->"
        end
    end
end

connection.close
