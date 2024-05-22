require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'pry-byebug'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)

  cleaned_numbers = phone_number.gsub(/\D/, '')

  if cleaned_numbers.length < 10 || cleaned_numbers.length > 11
    return nil
  elsif cleaned_numbers.length == 11 && cleaned_numbers[0] == "1"
    cleaned_numbers = format_phone_number(cleaned_numbers[1..-1])

  elsif cleaned_numbers.length == 10
    return format_phone_number(cleaned_numbers)
  end

end

def format_phone_number(phone_number)
  splitted = phone_number.split('')
  area_code = splitted[0..2].join
  three_first = splitted[3..5].join
  last_four = splitted.last(4).join

  formatted = "(#{area_code}) #{three_first}-#{last_four}"

  return formatted
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)


def registration_time_frequency(contents)

  contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
  )

  time_frequency = contents.reduce(Hash.new(0)) do |result, row|

    date = row[:regdate]

    only_time = Time.strptime(date, "%m/%d/%y %H:%M").strftime("%H")

    result[only_time] += 1

    result

  end

  most_repeated_time = time_frequency.values.max

  times_with_most_frequency = time_frequency.select { |time, frequency| frequency == most_repeated_time}

  puts "The times with the most registration frequency are: #{times_with_most_frequency}"

end



def registration_day_frequency(contents)

  contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
    )

  day_frequency = contents.reduce(Hash.new(0)) do |result, row|

    date = row[:regdate]

    only_day = Date.strptime(date, "%m/%d/%y %H:%M").wday

    result[only_day] += 1

    result

  end

  most_repeated_day = day_frequency.values.max

  days_with_most_frequency = day_frequency.select { |day, frequency| frequency == most_repeated_day}

  day_names = {
    0 => "Monday",
    1 => "Tuesday",
    2 => "Wednesday",
    3 => "Thursday",
    4 => "Friday",
    5 => "Saturday",
    6 => "Sunday"
  }

  days_with_most_frequency_with_names = days_with_most_frequency.transform_keys { |key| day_names[key] }

  puts "The day with most frequency is: #{days_with_most_frequency_with_names}"

end

registration_time_frequency(contents)
registration_day_frequency(contents)


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|

  id = row[0]
  name = row[:first_name]
  number = clean_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

end
