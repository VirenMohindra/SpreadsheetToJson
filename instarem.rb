require 'net/http'
require 'json'

# converts arrays with spaces and capitalized letters to computer readable format
def dehumanize(result)
  result.map { |i| i.to_s.downcase.gsub(/ +/, '_') }
end

def sheet_to_json(id)
  sheet_number = 1
  # accounting for the six sheets on the document
  while sheet_number <= 6
    url = 'http://localhost:5000/api?id=' + id + '&rows=false&sheet=' + sheet_number.to_s
    uri = URI(url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)

    cols = data.first.last
    new_hash = {}

    case sheet_number
    when 1 # For Mandatory/ Optional Fields sheet
      countries = data['columns'].keys
      # remove unnecessary first element `masspayparameter`
      countries.shift
      # storing Main Columns Fields
      fields = data['columns']['masspayparameter']
      fields = dehumanize(fields)

      # clean up fields
      fields.each do |field|
        if field == 'remitter_account_type_(eg:_individual_/company)'
          field.replace('remitter_account_type')
        elsif field == 'beneficiary_bank_account_type_(eg:checking/_saving_)'
          field.replace('beneficiary_bank_account_type')
        elsif field == 'beneficiary_account_type_(eg:_individual_/company)'
          field.replace('beneficiary_account_type')
        end
      end

      countries.each do |country|
        # dont skip the single germany column but skip the combined array
        next if country.start_with? 'germanyfrance'
        next if country.start_with? 'nonlocalcurrency'
        new_hash[country] = {}
        fields.each_with_index do |field, i|
          cols[country][i] == 'Mandatory' ? cols[country][i] = true : cols[country][i]
          new_hash[country][field] = cols[country][i]
          # remove empty cells
          new_hash[country].delete(field) if new_hash[country][field] == 0
        end
      end

    when 2 # For Supported Non-Local Currencies sheet
      supported_currency = data['columns']['currencytransferred']
      countries = data['columns']['benficiarybankaccountcountry']

      new_hash.tap do |h|
        countries.zip(supported_currency).each do |key, value|
          (h[key] ||= []) << value
        end
      end

    when 5 # For Field Validation sheet
      countries = data['columns'].keys
      # remove unnecessary first element which is empty
      countries.shift

      fields = data['columns']['fields']
      fields.shift
      fields = dehumanize(fields)

      types = ['type', 'require', 'regExp', 'minLength', 'maxLength', 'lengthComments', 'comment']

      general_hash = {}
      india_hash = {}
      countries_hash = {}

      # conditional for generalrulesforallcorridors
      countries.each do |country|
        if country == 'generalrulesforallcorridors'
          general_hash['general'] = {}
          fields.each_with_index do |field, i|
            general_hash['general'][field] = {}
            types.each do
              # types and column names are hardcoded
              # if any more columns are added to the google sheet this will need to be updated
              # skips the first empty cell because the type is duplicated
              general_hash['general'][field]['type'] = cols['generalrulesforallcorridors'][i + 1]
              general_hash['general'][field]['require'] = cols['require'][i + 1]
              general_hash['general'][field]['regExp'] = cols['regexp'][i + 1]
              general_hash['general'][field]['minLength'] = cols['minlength'][i + 1]
              general_hash['general'][field]['maxLength'] = cols['maxlength'][i + 1]
              general_hash['general'][field]['lengthComments'] = cols['lengthcomments'][i + 1]
              general_hash['general'][field]['comment'] = cols['comment'][i + 1]

              # for require type, required is true, optional is false
              if general_hash['general'][field]['require'] == 'required'
                general_hash['general'][field]['require'] = true
              elsif general_hash['general'][field]['require'] == 'optional'
                general_hash['general'][field]['require'] = false
              end
            end
          end
        end
      end

      # remove empty cells
      general_hash.each do |_|
        fields.each do |field|
          types.each do |type|
            if general_hash['general'][field][type] == 0
              general_hash['general'][field].delete(type)
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
            india_hash['india'][field]['regExp_under_200k'] = cols['india200000inr'][i + 1]
            india_hash['india'][field]['regExp_over_200k']  = cols['india200000inr_2'][i + 1]
            # remove empty cells
            # TO DO: if India > 200K has regex it wont work, so copy into < 200K also
            india_hash['india'].delete(field) if india_hash['india'][field]['regExp_under_200k'] == 0
          end
        end
      end

      # After all modifications have been done for generalrulesforallcorridors, india and hong kong is skipped
      # caveat-specific countries, remove them from the array so you don't have too many next if methods
      countries.shift(10)

      # conditional for all other countries which only has one column, regexp type cols only
      # if more columns are added create own block and hardcode (similar to india and generalrules)
      # then add next if condition to this block OR move before srilanka and shift countries array
      countries.each do |country|
        countries_hash[country] = {}
        fields.each_with_index do |field, i|
          countries_hash[country][field] = {}
          countries_hash[country][field]['regExp'] = cols[country][i + 1]
          # remove empty cells
          if countries_hash[country][field]['regExp'] == 0
            countries_hash[country].delete(field)
          end
        end
      end

      new_hash.update(general_hash)
      new_hash.update(india_hash)
      new_hash.update(countries_hash)

    when 6 # For General Validations Sheet
      types = data['columns'].keys
      # Remove unnecessary first element generalvalidations
      types.shift
      fields = data['columns']['generalvalidations']
      fields = dehumanize(fields)

      fields.each_with_index do |field, i|
        new_hash[field] = {}
        types.each do |type|
          new_hash[field][type] = cols[type][i]
          # remove empty cells
          new_hash[field].delete(type) if new_hash[field][type] == 0
        end
      end
    end
    sheet_number += 1
  end

  File.delete('final.json') if File.exist?('final.json')
  File.write('final.json', JSON.pretty_generate(new_hash))
end

id = open('.env', 'r').read
sheet_to_json(id)
