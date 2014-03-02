
require 'date'
require 'mongo'
require 'net/http'
include Mongo

def download_and_update_temp_data
  # http://academic.udayton.edu/kissock/http/Weather/gsod95-current/allsites.zip
  
  puts "Downloading temp data..."

  Net::HTTP.start("academic.udayton.edu") do |http|
    resp = http.get("/kissock/http/Weather/gsod95-current/allsites.zip")
    open("allsites.zip", "w") do |file|
      file.write(resp.body)
    end
  end

  # clear old files in data folder
  FileUtils.rm_rf(Dir.glob('data/*'))
end

def load_station_data
end

def map_filename_to_station
  city_filenames = {}

  File.open('date-files.txt', 'r').each_line.with_index do |line, lineno|
    next if lineno <= 1

    tokens = line.split(/\s\s+/)
    filename = tokens[1]
    city = tokens[0]
    # puts "#{filename} #{city}"
    city_filenames[filename] = city
  end
end

def read_and_insert_temp_data
  Dir.foreach('data') do |filename|
    next if filename == '.' || filename == '..'
    next if File.extname(filename) != '.txt'

    file_basename = File.basename(filename, '.txt')

    File.open("data/#{filename}").each_line do |line|
      tokens = line.split()

      city = city_filenames[file_basename]

      month = tokens[0].to_i
      day = tokens[1].to_i
      year = tokens[2].to_i

      # create date from month, day, year
      begin
        # ruby mongo driver requires conversion to UTC time
        utc_time = DateTime.new(year, month, day).to_time.utc  
      rescue => msg
        # ignore bizarre handling of leap year
      end

      temp = tokens[3].to_i

      if temp != -99
        p "#{file_basename} #{month} #{day} #{year} #{temp}"

        # create record and insert into mongodb
        daily_temp = { :city => city, :date => utc_time, :temp => temp }

        begin
          daily_temps.insert(daily_temp)
        rescue Mongo::OperationFailure => e
          if e.message =~ /^11000/
            puts "Ignoring duplicate."
          else
            raise e
          end
        end
      end
    end
  end
end

# initialize mongodb
db = Connection.new.db('test')
daily_temps = db.collection('dailytemps')

#indexes
daily_temps.create_index({:date => Mongo::ASCENDING, :temp => Mongo::ASCENDING})
daily_temps.create_index({:date => Mongo::ASCENDING, :city => Mongo::ASCENDING}, :unique => true)

download_and_update_temp_data
