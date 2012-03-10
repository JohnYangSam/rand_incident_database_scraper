#!/usr/bin/env ruby

#Program: randScraper.rb
#Author: John Yang-Sammataro
#Last Updated: 3/8/2012
#-------------------------
#This is a ruby program using Mechanize and Nokogiri to scrape data
#from the RAND Terrorism Incidents Database (http://smapp.rand.org/rwtid/search_form.php)
#The program outputs a CSV file where the rows are incidents and the columns are
#[Date, Location, group responsible, Weapon Type, Injuries, Fatalities, Description].
#
#This scraper involves a catch that will throw an exception and stop the
#program if the files it writes already exist (this prevents writing over
#data that may take a while to scrape again.

#Load libraries
require 'rubygems';
require 'mechanize';
require 'nokogiri';

#Global variables
#To keep count of how many profiles on the command line
$incidentCount = 0;

#Constants
randDatabaseURL = "http://smapp.rand.org/rwtid/search_form.php";
outputFileName = 'randTerrorismIncidents.csv';
databaseStartYear = 1968;
currentYear = Time.new().year;

#Methods

#signalProcessCompletion()
#Recieves: nothing
#Processes: increments the incidentCount gobal variable and prints to
#the console the number of incidents processed
def signalProcessCompletion()
  $incidentCount +=1;
  puts $incidentCount;
end

#processSection0(section)
#Recieves: the first section of the incident page and the incident string
#Processes: extracting information from the section
#Returns: a beginning csv entry string of the date, location, and group responsible
def processSection0(section)
  string = '';
  buffer_array = [];
  text = section.inner_html;
  text.split('<br>').each do |info|
    buffer_array << info.strip().delete(',');
  end
  string += buffer_array.join(",");
  return string;
end

#processSection1(section)
#Recieves: the second section of the incident page
#Processes: extracting information from the section
#Returns: an ending csv entry string of the incident weapon type, injuries, and fatalities
def processSection1(section)
  string = '';
  buffer_array = [];
  text = section.inner_html;
  text.split('<br>').each do |info|
    data = info.split(':')[1].strip().delete(','); #Extract data leaving out tags
    string += ',';
    string += data;
  end
  return string;
end

#processSection2(section)
#Recieves: the third section of the incident page
#Processes: extracting information from the section
#Returns: an ending csv entry string of the incident description
def processSection2(section)
  string = '';
  text = section.inner_html
  text = text.delete('<p>').strip().delete('\/').delete(','); #clean up string
  string += ',';
  string += text;
  return string;
end

#processIncidentPage(agent, page, output)
#Recieves: an agent, page, and output file
#Processes: extracts the incident information and writes it to a csv
def processIncidentPage(agent, page, output)
  doc = Nokogiri::HTML(page.body);
  incident_info = '';

  #Get all information and store it in the incident_information array
  sections = doc.css('tr td')
  incident_info += processSection0(sections[0]);
  incident_info += processSection1(sections[1]);
  incident_info += processSection2(sections[2]);

  #Convert the array to a CSV line and Write to CSV
  output.puts(incident_info);
  signalProcessCompletion();
end

#checkForFileExistence(fileName)
#Receives: a file name string
#Processes: raises an error if the file already exists
def checkForFileExistence(fileName)
  raise "#{fileName} file already exists" if File.exist?(fileName);
end

#showInformation()
#Receives: nothing
#Processes: prints out information about the program to the user
def showInformation()
  print("Starting up the scraper for the RAND Terrorism Incident Database.  The flashing numbers that will appear represent written incidents. It will take a few moments for the initial program to load... \n");
end

#submitIncidentForm(page, startYear, endYear)
#Recieves: a mechanize page and startYear and endYear integers
#Processes: submitting the incident form with the appropriate years
#Returns: the resutlng page from the form submission
def submitIncidentForm(page, startYear, endYear)
  form = page.form_with(:action => "search.php");
  form['start_year'] = startYear;
  form['end_year'] = endYear;
  page = page.form_with(:action => "search.php").click_button();
end


########################################
#                 MAIN                 #
########################################

showInformation();

#Create output files
begin
  #Avoid writing over files
#  checkForFileExistence(outputFileName);
  output = File.open(outputFileName, 'w');
rescue
  abort("Aborted to prevent overwriting files");
end

year = databaseStartYear;
while(year <= currentYear)

  #Create a new Mechanize agent and open the Rand Database main page
  agent = Mechanize.new();
  agent.idle_timeout = 0.1; #This corrects a "too many connection resets" error
  page = agent.get(randDatabaseURL);

  incidents_page = submitIncidentForm(page, year, year + 5);

  #Get and process each link
  doc = Nokogiri::HTML(incidents_page.body);
  doc.css("div#content > div#indent > ol > li > a").each do |node|
    incident_page = Mechanize::Page::Link.new(node, agent, page).click();
    processIncidentPage(agent, incident_page, output);
  end

  year += 5;

end

#Close output file
output.close();
