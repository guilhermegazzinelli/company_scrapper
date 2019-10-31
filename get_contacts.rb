#!/usr/bin/env ruby
require 'mechanize'
require 'oj'

# require 'csv'
# require 'rubyful_soup'

# require 'active_record'
require 'sqlite3'

require './color_string_extension'

@database = "db/companies"
@verbose = false
@pinwheel = %w{ | / - \\ }



if ARGV[0].nil? || ARGV[1].nil?
    puts 'Usage:'
    puts "\t" + __FILE__ + ' [database] [database_path] '
    puts 'Where:'
    puts "\tdatabase: can be nod_db, sqlite, csv or both - Just sqlite enabled for now"
    puts "\tdatabase_path: default = db/companies"
    puts
    exit 0
end

def import_all_category_companies category
    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue
    puts "                   Importing subcategory".red
    puts "  #{category}"
    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue

    url = "https://www.cadastroindustrialmg.com.br:449/industria/resultadobusca?Filters=Setor:#{category};&K=#{category.split()[0]}"
    show_company_root = "https://www.cadastroindustrialmg.com.br:449/industria/index/"


    firstpage = @agent.get(url)
    aux = firstpage.link_with(:href => '#', :id => "id_empresas_buy")
    if !aux
        return 0
    end
    ids = firstpage.link_with(:href => '#', :id => "id_empresas_buy").attributes["data-ids"].split(',')
    @db.execute "INSERT INTO Categories(name) VALUES ('#{category}')"
    category_id = @db.execute "SELECT id FROM Categories ORDER BY id DESC limit 1;"
    category_id = category_id[0][0]

    ids.each.with_index do |id, idx|

      percentage = (idx.to_f / ids.length * 100).to_i
      print "\b" * 16, "Progress: #{percentage}% ", @pinwheel.rotate!.first
      puts
      # puts "ID: #{id}"
      # puts "#{show_company_root}#{id}"
      c = @agent.get("#{show_company_root}#{id}")
      name    = c.search(".//div[@class='descricao']").text.tr("'", "")
      links   = c.search(".//div[@class='links']")
      email   = links.search(".//a[starts-with(@href, 'mailto')]").text if links.search(".//a[starts-with(@href, 'mailto')]").text
      website = links.search(".//a[starts-with(@href, 'http')]").text if links.search(".//a[starts-with(@href, 'http')]").text
      phone   = c.search(".//div[@class='contato']").search(".//span").children[1].text.tr("'", "")
      
      infos = c.search(".//div[@class='info']")
      cnae    = infos[0].children[3].text.tr("'", "").tr("'", "")
      serv    = infos[1].children[3].text.tr('\"','').tr("'", "")
      size    = infos[2].children[3].text.tr("'", "")
      address = c.search(".//div[@class='endereco']").text.tr("'", "")
      if @verbose
        puts "_______________________________________________________"
        puts "Empresa: #{name.red}"
        puts "Telefone: #{phone.blue}"
        puts "email: #{email.yellow}"
      end
        @db.execute "INSERT INTO Companies(name, email, source_link, phone, website, cnae, serv, size, address, category_id ) VALUES ('#{name}', '#{email}', '#{show_company_root}#{id}', '#{phone}', '#{website}', '#{cnae}', '#{serv}', '#{size}',  '#{address}', '#{category_id}')"

    end    
    
end
def import_subcategories_names

    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue
    puts "                   Importing Subcategories".red
    puts "____________________________________________________________".blue

    sub_categories_name = []

    for cat_id in 2..95 do 
        c = Oj.load(@agent.post("https://www.cadastroindustrialmg.com.br:449/industria/setor","Id"=>cat_id ).body)[0]["subCategoria"]
        if c.size > 0
            c.each { |cat| sub_categories_name << cat["Nome"]}
        end
    end
    puts "Imported #{sub_categories_name.size.to_s.bold} Sub-categories"
    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue

    return sub_categories_name
end

def create_database
    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue
    puts "                   Creating Database".red
    puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue
    
    begin
        db = SQLite3::Database.new @database
        db.execute "CREATE TABLE Categories(id INTEGER PRIMARY KEY, name TEXT, companies_count TEXT)"
        db.execute <<-SQL
          CREATE TABLE Companies (
            id INTEGER PRIMARY KEY,
            name TEXT,
            email TEXT,
            source_link TEXT,
            phone TEXT,
            website TEXT,
            cnae TEXT,
            serv TEXT,
            size TEXT,
            export TEXT,
            address TEXT, 
            category_id INTEGER, 
            FOREIGN KEY(category_id) REFERENCES Categories(id)
          )
        SQL

    rescue SQLite3::Exception => e         
        puts "                 Exception occurred".red
        puts e
        puts "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++".blue
        
    ensure
        db.close if db
    end

end

def open_database
    @db = SQLite3::Database.open @database
end

def close_database
    @db.close if @db
end


# require 'nokogiri'
# require 'open-uri'

# class SoupParser < Mechanize::Page
#     attr_reader :soup
#     def initialize(uri = nil, response = nil, body = nil, code = nil)
#       @soup = BeautifulSoup.new(body)
#       super(uri, response, body, code)
#     end
#   end
create_database()
open_database()

@agent = Mechanize.new

sub_categories =  import_subcategories_names()

sub_categories.each do |sc|
    import_all_category_companies(sc)

end

# @agent.pluggable_parser.html = SoupParser

# url = 'https://www.cadastroindustrialmg.com.br:449/industria/resultadobusca?K=Fundi%C3%A7%C3%A3o&Filters=Setor:Fundi%C3%A7%C3%A3o%20de%20ferro%20e%20a%C3%A7o;&Page='
# url = 'https://www.cadastroindustrialmg.com.br:449/industria/resultadobusca?Filters=Setor:Fundição%20de%20metais%20não-ferrosos%20e%20suas%20ligas;&K=Fundição'
# firtspage = @agent.get("#{url}")

# show_company_root = "https://www.cadastroindustrialmg.com.br:449/industria/index/"
# # puts "#{url}#{page}"
# sub_categories_name = []

# for cat_id in 2..95 do 
#     c = Oj.load(@agent.post("https://www.cadastroindustrialmg.com.br:449/industria/setor","Id"=>cat_id ).body)[0]["subCategoria"]
#     if c.size > 0
#         c.each { |cat| sub_categories_name << cat["Nome"]}
#     end
# end








    # puts l.text

# firtspage.find_all('ul').each do |e|    
#     puts e
#     e.search(a).each do |link|

#     end
# end





