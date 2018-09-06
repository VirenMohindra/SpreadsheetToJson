require 'net/http'
require 'json'

# Takes SpreadSheet id and sheet number as arg, default for sheet_number is (Mandatory/ Optional Fields, integer 1)
def sheet_to_json(id, sheet_number = 1)
  url = 'http://localhost:5000/api?id=' + id + '&rows=false&sheet=' + sheet_number.to_s
  uri = URI(url)
  response = Net::HTTP.get(uri)

  data = JSON.parse(response)
  cols = data.first.last
  new_hash = {}
  case sheet_number
  when 1 # For Mandatory/ Optional Fields sheet
    countries = data['columns'].keys
    # Remove unnecessary first element `masspayparameter`
    countries.shift
    # Storing Main Columns Fields
    fields = data['columns']['masspayparameter']

    countries.each do |key|
      new_hash[key] = {}
      fields.each_with_index do |name, i|
        new_hash[key][name] = cols[key][i]
      end
    end

  when 2 # For Supported Non-Local Currencies sheet
    # not sure how to format
    new_hash = { 'to do list' => 'test' }

  when 5 # For Field Validation sheet
    countries = data['columns'].keys
    # Remove unnecessary first element which is empty
    countries.shift

    fields = data['columns']['_cn6ca']
    fields.shift

    types = ['type', 'require', 'regExp', 'len']

    # partial hashes which will later get combined
    general_hash = {}
    india_hash = {}
    countries_hash = {}

    # conditional for all corridors, currently only supports regExp (one column)
    countries.each do |country|
      if country == 'generalrulesforallcorridors'
        general_hash['general'] = {}
        fields.each_with_index do |field, i|
          general_hash['general'][field] = {}
          types.each do
            # types and column names are hardcoded
            # if any more columns are added to the google sheet this will need to be updated
            general_hash['general'][field]['type']    = cols['generalrulesforallcorridors'][i + 1]
            general_hash['general'][field]['require'] = cols['_cpzh4'][i + 1]
            general_hash['general'][field]['regExp']  = cols['_cre1l'][i + 1]
            general_hash['general'][field]['len']     = cols['_chk2m'][i + 1]
          end
        end
      end
    end

    # conditional for India, since its two columns
    countries.each do |country|
      if country == 'india200000inr'
        india_hash['india'] = {}
        fields.each_with_index do |field, i|
          india_hash['india'][field] = {}
          types.each do
            # types and column names are hardcoded
            # if any more columns are added to the google sheet this will need to be updated
            # next if cols['india200000inr'][i+1] == 0
            india_hash['india'][field]['regExp_under_200k'] = cols['india200000inr'][i + 1]
            india_hash['india'][field]['regExp_over_200k']  = cols['india200000inr_2'][i + 1]
          end
        end
      end
    end

    # for every other country which only has one column, sticking to strict regexp type cols only
    # if more columns are added create own block and hardcode
    # then add next if condition to this block
    countries.each do |country|
      next if country == 'generalrulesforallcorridors'
      next if country == '_cpzh4'
      next if country == '_cre1l'
      next if country == '_chk2m'
      next if country == '_ckd7g'
      next if country == '_ciyn3'
      next if country == 'india200000inr'
      next if country == 'india200000inr_2'
      countries_hash[country] = {}
      fields.each_with_index do |field, i|
        countries_hash[country][field] = {}
        types.each do
          countries_hash[country][field]['regExp'] = cols[country][i + 1]
        end
      end
    end

    # append partial hashes to main hash
    new_hash.update(general_hash)
    new_hash.update(india_hash)
    new_hash.update(countries_hash)

    # for india and two column countries
    new_hash.each do |country, value|
      next unless country == 'india'
      # india has 2 columns
      value.each do |field, _|
        if new_hash['india'][field]['regExp_under_200k'] == 0
          new_hash['india'].delete(field)
        elsif new_hash['india'][field]['regExp_over_200k'] == 0
          new_hash['india'].delete(field)
        end
      end
    end

    # for all corridors and countries
    new_hash.each do |country, value|
      # india has 2 columns so its ignored here
      next if country == 'india'
      value.each do |field, key|
        key.each do |regexp, _|
          if new_hash[country][field][regexp] == 0
            new_hash[country].delete(field)
          end
        end
      end
    end

  when 6 # For General Validations Sheet
    types = data['columns'].keys
    # Remove unnecessary first element generalvalidations
    types.shift
    fields = data['columns']['generalvalidations']

    fields.each_with_index do |field, i|
      new_hash[field] = {}
      types.each do |type|
        new_hash[field][type] = cols[type][i]
      end
    end
  end

  File.delete('final.json') if File.exist?('final.json')
  File.write('final.json', JSON.pretty_generate(new_hash))
end

# load sheet id
id = open('.env', 'r').read
# default integer (1), 2, 5, 6 as args
sheet_to_json(id, 6)
