require 'faker'

describe "PerfSpecHelper", :shared => true do
  
  def get_test_data(num=1000)
    file = File.join("spec","testdata","#{num}-data.txt")
    data = nil
    if File.exists?(file)
      data = open(file, 'r') {|f| Marshal.load(f)}
    else
      data = generate_fake_data(num)
      f = File.new(file, 'w')
      f.write Marshal.dump(data)
      f.close
    end
    data
  end
  
  def lap_timer(msg,start)
    duration = timenow - start
    puts "#{msg}: #{duration}"
    timenow
  end
  
  def start_timer
    timenow
  end
  
  private

  PREFIX = ["Account", "Administrative", "Advertising", "Assistant", "Banking", "Business Systems", 
    "Computer", "Distribution", "IT", "Electronics", "Environmental", "Financial", "General", "Head", 
    "Laboratory", "Maintenance", "Medical", "Production", "Quality Assurance", "Software", "Technical", 
    "Chief", "Senior"] unless defined? PREFIX
  SUFFIX = ["Clerk", "Analyst", "Manager", "Supervisor", "Plant Manager", "Mechanic", "Technician", "Engineer", 
    "Director", "Superintendent", "Specialist", "Technologist", "Estimator", "Scientist", "Foreman", "Nurse", 
    "Worker", "Helper", "Intern", "Sales", "Mechanic", "Planner", "Recruiter", "Officer", "Superintendent",
    "Vice President", "Buyer", "Production Supervisor", "Chef", "Accountant", "Executive"] unless defined? SUFFIX
  
  def title
    prefix = PREFIX[rand(PREFIX.length)]
    suffix = SUFFIX[rand(SUFFIX.length)]

    "#{prefix} #{suffix}"
  end

  def generate_fake_data(num=1000)
    res = {}
    num.times do |n|
      res[n.to_s] = {
        "FirstName" => Faker::Name.first_name,
        "LastName" => Faker::Name.last_name,
        "Email" =>  Faker::Internet.free_email,
        "Company" => Faker::Company.name,
        "JobTitle" => title,
        "Phone1" => Faker::PhoneNumber.phone_number
      }
    end
    res
  end
  
  def timenow
    (Time.now.to_f * 1000)
  end
end