
require 'mongo'
require 'date'
include Mongo

# initialize mongodb
db = Connection.new.db('test')
daily_temps = db.collection('dailytemps')

#indexes
daily_temps.create_index({:date => Mongo::ASCENDING, :temp => Mongo::ASCENDING})
daily_temps.create_index({:date => Mongo::ASCENDING, :city => Mongo::ASCENDING}, :unique => true)

city_filenames = {}

# map filename to city
File.open('cities.txt', 'r').each_line.with_index do |line, lineno|
  next if lineno <= 1

  tokens = line.split(/\s\s+/)
  filename = tokens[1]
  city = tokens[0]
  # puts "#{filename} #{city}"
  city_filenames[filename] = city
end

# load data files
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
