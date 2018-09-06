# SpreadSheetToJson
Follow instructions [here](https://github.com/55sketch/gsx2json) to grab `id` from your google drive sheet and set up the api.

### Setup
Create `.env` file following `.env.sample` guidelines. This is the long aplha-numeric code in the middle of your document URL, which looks something like this:
- `1xcOoLJqXYrL_oVRsHoInKwN6V7bP-tisL1rChw4m3OE`

Clone the git repository, downloading directly as a zip file will not have the .git folder included
```sh
$ git clone https://github.com/VirenMohindra/SpreadsheetToJson.git
$ cd SpreadsheetToJson/
$ git submodule init
$ git submodule update
```
This will grab the latest version of gsx2json and update the submodules.

### API
[Gsx2Json](https://github.com/55sketch/gsx2json) handles converting the spreadsheet output to cleaner json.
Open a new terminal window, `cd` into the `gsx2json` project directory and then
```sh
$ npm install
$ node app
```
This is currently added as a submodule to this project.

### Running `instarem.rb`
Open a new terminal window, `cd` into project directory and then
```sh
gem install filewatcher
$ filewatcher '**/*.rb' 'time ruby instarem.rb
```
If constant reloading with [filewatcher](https://github.com/thomasfl/filewatcher) isn't required `ruby instarem.rb` will work as well.


### Linting
Linting is performed through [Rubocop](https://github.com/rubocop-hq/rubocop)
```sh
$ gem install rubocop
$ rubocop
```
Rules are in `.rubocop.yml`

### Testing

WIP

### Caveats
> Sheet needs to be published for web, security might be compromised.