from os.path import exists
import urllib.request
import json

bulk_data_url = 'https://api.scryfall.com/bulk-data'
bulk_data_response = urllib.request.urlopen(bulk_data_url)
bulk_data = json.loads(bulk_data_response.read())
for item in bulk_data['data']:
    if item['type'] == 'default_cards':
        card_data_url = item['download_uri']
        last_remote_update = item['updated_at']

if exists('Scryfall.updated'):
    with open('Scryfall.updated', 'r') as file:
        last_local_update = file.read()
    if last_remote_update <= last_local_update:
        quit("Local files are already fresh, don't need to dowload, exiting.")
    else:
        print("Local files are out-of-date, downloading update...")
else:
    print("Last update timestamp not found, downloading update...")
        
card_data_response = urllib.request.urlopen(card_data_url)
card_data = json.loads(card_data_response.read())
print("Bulk data download complete, splitting into sets...")

cards_by_set = {}
for card in card_data:
    set_code = card['set'].upper()
    if not set_code in cards_by_set:
        cards_by_set[set_code] = []
    cards_by_set[set_code].append(card)
    
for set_code, set_data in cards_by_set.items():
    with open('Scryfall/' + set_code + '_.txt', 'w', encoding="utf8") as outfile:
        json.dump(set_data, outfile, separators=(',', ':'))
with open('Scryfall.updated', 'w') as file:
    file.write(last_remote_update)
print("Set files complete and ready for use in Magic Album, exiting.")
