--[[------------------------------------------
Price import script for scryfall.com
Modified: tenminutegod
Last update: 2024.11.12
Based on MTG Mint Card script by Goblin Hero
ver 2024.11.12

Create jsonLua folder in Prices, download https://github.com/rxi/json.lua to the folder
Run Scryfall.py to download and split bulk data from Scryfall (~450MB)
Scryfall folder can be removed after prices have been parsed
--------------------------------------------]]

--[[ Logging Options
    LOG_FAILURE     Log SetPrice failure
    LOG_SUCCESS     Log SetPrice success
    LOG_INITIAL     Log SetPrice in parse_card
    LOG_REPARSE     Log SetPrice in reparse_failed_cards
    SHOW_MORE       Print some additional card data
    DUMP_JSON       Dump each card's JSON data
--]]
LOG_FAILURE = false
LOG_SUCCESS = false
LOG_INITIAL = false
LOG_REPARSE = true
SHOW_MORE   = false
DUMP_JSON   = false

--[[ Other Options
    TEST_PRICES     Sets every price that matches to 1.00
]]--
TEST_PRICES = false

-- Library needed for parsing the JSON files from Scryfall (https://github.com/rxi/json.lua)
json = dofile('Prices/jsonLua/json.lua')

--[[ Table that describes sets available for price import
    id              numerical database set id (can be found in 'Database\Sets.txt' file)
    code            the set code for the set on Scryfall
    is_promo_set    filters out any cards not tagged by Scryfall as promos
--]]
available_sets = {
    {id = 1018, code = 'DSC'},      --Duskmourn: House of Horror Commander
    {id = 1017, code = 'DSK', is_promo_set = true },    --Duskmourn: House of Horror Promos
    {id = 1017, code = 'PDSK'},     --Duskmourn: House of Horror Promos
    {id = 1016, code = 'DSK'},      --Duskmourn: House of Horror
    {id = 1015, code = 'BLC'},      --Bloomburrow Commander
    {id = 1014, code = 'PBLB'},     --Bloomburrow Promos
    {id = 1014, code = 'BLB', is_promo_set = true },    --Bloomburrow Promos
    {id = 1013, code = 'BLB'},	    --Bloomburrow
    {id = 1012, code = 'ACR'},      --Assassin’s Creed
    {id = 1011, code = 'M3C'},      --Modern Horizons 3 Commander
    {id = 1010, code = 'PMH3'},     --Modern Horizons 3 Promos
    {id = 1009, code = 'MH3'},      --Modern Horizons 3
    {id = 1008, code = 'OTC'},      --Outlaws of Thunder Junction Commander
    {id = 1007, code = 'BIG'},      --The Big Score
    {id = 1006, code = 'OTP'},      --Breaking News
    {id = 1005, code = 'POTJ'},     --Outlaws of Thunder Junction Promos
    {id = 1005, code = 'OTJ', is_promo_set = true },    --Outlaws of Thunder Junction Promos
    {id = 1004, code = 'OTJ'},      --Outlaws of Thunder Junction
    {id = 1003, code = 'PIP'},      --Fallout
    {id = 1002, code = 'CLU'},      --Ravnica: Clue Edition
    {id = 1001, code = 'MKC'},      --Murders at Karlov Manor Commander
    {id = 1000, code = 'PMKM'},     --Murders at Karlov Manor Promos
    {id = 1000, code = 'MKM', is_promo_set = true },    --Murders at Karlov Manor Promos
    {id = 999,  code = 'MKM'},      --Murders at Karlov Manor
    {id = 998,  code = 'RVR'},      --Ravnica Remastered
    {id = 997,  code = 'SPG'},      --Special Guests
    {id = 996,  code = 'REX'},      --Jurassic World Collection
    {id = 995,  code = 'LCC'},      --The Lost Caverns of Ixalan Commander
    {id = 994,  code = 'PLCI'},     --The Lost Caverns of Ixalan Promos
    {id = 994,  code = 'LCI', is_promo_set = true },    --The Lost Caverns of Ixalan Promos
    {id = 993,  code = 'LCI'},      --The Lost Caverns of Ixalan
    {id = 992,  code = 'WHO'},      --Doctor Who Commander
    {id = 991,  code = 'WOC'},      --Wilds of Eldraine Commander
    {id = 990,  code = 'WOT'},      --Enchanting Tales
    {id = 989,  code = 'PWOE'},     --Wilds of Eldraine Promos
    {id = 989,  code = 'WOE', is_promo_set = true },    --Wilds of Eldraine Promos
    {id = 988,  code = 'WOE'},      --Wilds of Eldraine
    {id = 987,  code = 'CMM'},      --Commander Masters
    {id = 986,  code = 'LTC'},      --The Lord of the Rings Commander
    {id = 985,  code = 'PLTR'},     --The Lord of the Rings Promos
    {id = 985,  code = 'LTR', is_promo_set = true },    --The Lord of the Rings Promos
    {id = 984,  code = 'LTR'},      --The Lord of the Rings
    {id = 983,  code = 'MAT'},      --March of the Machine: The Aftermath
    {id = 982,  code = 'MUL'},      --Multiverse Legends
    {id = 981,  code = 'MOC'},      --March of the Machine Commander
    {id = 980,  code = 'PMOM'},     --March of the Machine Promos
    {id = 980,  code = 'MOM', is_promo_set = true },    --March of the Machine Promos
    {id = 979,  code = 'MOM'},      --March of the Machine
    {id = 978,  code = 'DMR'},      --Dominaria Remastered
    {id = 977,  code = 'J22'},      --Jumpstart 2022
    {id = 976,  code = 'ONC'},      --Phyrexia: All Will Be One Commander
    {id = 975,  code = 'PONE'},     --Phyrexia: All Will Be One Promos
    {id = 975,  code = 'ONE', is_promo_set = true },    --Phyrexia: All Will Be One Promos
    {id = 974,  code = 'ONE'},      --Phyrexia: All Will Be One
    {id = 973,  code = 'P30A'},     --30th Anniversary Play Promos
    {id = 973,  code = 'P30M'},     --30th Anniversary Play Promos
    {id = 972,  code = 'BOT'},      --Transformers
    {id = 971,  code = 'BRC'},      --The Brothers' War Commander
    {id = 970,  code = 'BRR'},      --The Brothers' War Retro Artifacts
    {id = 969,  code = 'PBRO'},     --The Brothers' War Promos
    {id = 969,  code = 'BRO', is_promo_set = true },    --The Brothers' War Promos
    {id = 968,  code = 'BRO'},      --The Brothers' War
    {id = 967,  code = 'SLC'},      --Secret Lair 30th Anniv. Countdown Kit
    {id = 966,  code = 'GN3'},      --Game Night: Free-For-All
    {id = 965,  code = 'PNCC'},     --Streets of New Capenna Commander Promos
    {id = 964,  code = 'UNF'},      --Unfinity
    {id = 963,  code = '40K'},      --Warhammer 40000 Commander
    {id = 962,  code = 'DMC'},      --Dominaria United Commander
    {id = 961,  code = 'PDMU'},     --Dominaria United Promos
    {id = 961,  code = 'DMU', is_promo_set = true },    --Dominaria United Promos
    {id = 960,  code = 'DMU'},      --Dominaria United
    {id = 959,  code = 'PM21'},     --Core Set 2021 Promos
    {id = 959,  code = 'M21', is_promo_set = true },    --Core Set 2021 Promos
    {id = 958,  code = '2X2'},      --Double Masters 2022
    {id = 957,  code = 'PCLB'},     --Commander Legends: Baldur's Gate Promos
    {id = 957,  code = 'CLB', is_promo_set = true },    --Commander Legends: Baldur's Gate Promos
    {id = 956,  code = 'CLB'},      --Commander Legends: Baldur's Gate
    {id = 955,  code = 'Q06'},      --Pioneer Challenger Decks
    {id = 954,  code = 'SLX'},      --Universes Within
    {id = 953,  code = 'NCC'},      --Streets of New Capenna Commander
    {id = 952,  code = 'PSNC'},     --Streets of New Capenna Promos
    {id = 952,  code = 'SNC', is_promo_set = true },    --Streets of New Capenna Promos
    {id = 951,  code = 'SNC'},      --Streets of New Capenna
    {id = 950,  code = 'PH20'},     --Heroes of the Realm Promos
    {id = 950,  code = 'PH19'},     --Heroes of the Realm Promos
    {id = 950,  code = 'PH18'},     --Heroes of the Realm Promos
    {id = 950,  code = 'PH17'},     --Heroes of the Realm Promos
    {id = 950,  code = 'PHTR'},     --Heroes of the Realm Promos
    {id = 949,  code = 'NEC'},      --Kamigawa: Neon Dynasty Commander
    {id = 948,  code = 'PNEO'},     --Kamigawa: Neon Dynasty Promos
    {id = 948,  code = 'NEO', is_promo_set = true },    --Kamigawa: Neon Dynasty Promos
    {id = 947,  code = 'NEO'},      --Kamigawa: Neon Dynasty
    {id = 946,  code = 'CC2'},      --Commander Collection: Black
    {id = 945,  code = 'DBL'},      --Innistrad Double Feature
    {id = 944,  code = 'OVOC'},     --Innistrad: Crimson Vow Commander (Display)
    {id = 944,  code = 'VOC'},      --Innistrad: Crimson Vow Commander
    {id = 943,  code = 'PVOW'},     --Innistrad: Crimson Vow Promos
    {id = 943,  code = 'VOW', is_promo_set = true },    --Innistrad: Crimson Vow Promos
    {id = 942,  code = 'VOW'},      --Innistrad: Crimson Vow
    {id = 941,  code = 'OMIC'},     --Innistrad: Midnight Hunt Commander (Display)
    {id = 941,  code = 'MIC'},      --Innistrad: Midnight Hunt Commander
    {id = 940,  code = 'PMID'},     --Innistrad: Midnight Hunt Promos
    {id = 940,  code = 'MID', is_promo_set = true },    --Innistrad: Midnight Hunt Promos
    {id = 939,  code = 'MID'},      --Innistrad: Midnight Hunt
    {id = 938,  code = 'PLST'},     --The List
    {id = 938,  code = 'ULST'},     --The List
    {id = 937,  code = 'PLG22'},    --Love Your LGS Promos
    {id = 937,  code = 'PLG21'},    --Love Your LGS Promos
    {id = 937,  code = 'PLG20'},    --Love Your LGS Promos
    {id = 936,  code = 'OAFC'},     --Forgotten Realms Commander (Display)
    {id = 936,  code = 'AFC'},      --Forgotten Realms Commander
    {id = 935,  code = 'PAFR'},     --Adventures in the Forgotten Realms Promo
    {id = 935,  code = 'AFR', is_promo_set = true },    --Adventures in the Forgotten Realms Promo
    {id = 934,  code = 'AFR'},      --Adventures in the Forgotten Realms
    {id = 933,  code = 'H1R'},      --Modern Horizons Timeshifts
    {id = 932,  code = 'PMH2'},     --Modern Horizons 2 Promos
    {id = 932,  code = 'MH2', is_promo_set = true },    --Modern Horizons 2 Promos
    {id = 931,  code = 'MH2'},      --Modern Horizons 2
    {id = 930,  code = 'OC21'},     --Commander 2021 (Display)
    {id = 930,  code = 'C21'},      --Commander 2021
    {id = 929,  code = 'PSTX'},     --Strixhaven: School of Mages Promos
    {id = 929,  code = 'STX', is_promo_set = true },    --Strixhaven: School of Mages Promos
    {id = 928,  code = 'STA'},      --Strixhaven Mystical Archive
    {id = 927,  code = 'STX'},      --Strixhaven: School of Mages
    {id = 926,  code = 'PBBD'},     --Battlebond Promos
    {id = 925,  code = 'SS3'},      --Signature Spellbook: Chandra
    {id = 924,  code = 'TSR'},      --Time Spiral Remastered
    {id = 923,  code = 'SLU'},      --Secret Lair: Ultimate Edition
    {id = 922,  code = 'PBFZ'},     --Battle for Zendikar Promos
    {id = 921,  code = 'L15'},      --League Tokens
    {id = 921,  code = 'L16'},      --League Tokens
    {id = 921,  code = 'L14'},      --League Tokens
    {id = 921,  code = 'L13'},      --League Tokens
    {id = 921,  code = 'L17'},      --League Tokens
    {id = 921,  code = 'L12'},      --League Tokens
    {id = 920,  code = 'PKHM'},     --Kaldheim Promos
    {id = 920,  code = 'KHM', is_promo_set = true },    --Kaldheim Promos
    {id = 919,  code = 'KHC'},      --Kaldheim Commander
    {id = 918,  code = 'KHM'},      --Kaldheim
    {id = 917,  code = 'PLST'},     --Mystery Booster
    {id = 916,  code = 'PFRF'},     --Fate Reforged Promos
    {id = 915,  code = 'G17'},      --Gift Pack 2017
    {id = 914,  code = 'CC1'},      --Commander Collection: Green
    {id = 913,  code = 'PTG'},      --Ponies: The Galloping
    {id = 912,  code = 'PF20'},     --MagicFest Promos
    {id = 912,  code = 'PF19'},     --MagicFest Promos
    {id = 911,  code = 'CMR'},      --Commander Legends
    {id = 910,  code = 'PAKH'},     --Amonkhet Promos
    {id = 909,  code = 'PAER'},     --Aether Revolt Promos
    {id = 908,  code = 'PIKO'},     --Ikoria: Lair of Behemoths Promos
    {id = 908,  code = 'IKO', is_promo_set = true },    --Ikoria: Lair of Behemoths Promos
    {id = 907,  code = 'PTHB'},     --Theros Beyond Death Promos
    {id = 907,  code = 'THB', is_promo_set = true },    --Theros Beyond Death Promos
    {id = 906,  code = 'PELD'},     --Throne of Eldraine Promos
    {id = 906,  code = 'ELD', is_promo_set = true },    --Throne of Eldraine Promos
    {id = 905,  code = 'PM20'},     --Core Set 2020 Promos
    {id = 905,  code = 'PPP1'},     --Core Set 2020 Promos
    {id = 905,  code = 'M20', is_promo_set = true },    --Core Set 2020 Promos
    {id = 904,  code = 'PWAR'},     --War of the Spark Promos
    {id = 904,  code = 'WAR', is_promo_set = true },    --War of the Spark Promos
    {id = 903,  code = 'PRNA'},     --Ravnica Allegiance Promos
    {id = 903,  code = 'RNA', is_promo_set = true },    --Ravnica Allegiance Promos
    {id = 902,  code = 'PGRN'},     --Guilds of Ravnica Promos
    {id = 902,  code = 'GRN', is_promo_set = true },    --Guilds of Ravnica Promos
    {id = 901,  code = 'PM19'},     --Core Set 2019 Promos
    {id = 901,  code = 'M19', is_promo_set = true },    --Core Set 2019 Promos
    {id = 900,  code = 'ZNC'},      --Zendikar Rising Commander
    {id = 899,  code = 'ZNE'},      --Zendikar Rising Expeditions
    {id = 898,  code = 'PZNR'},     --Zendikar Rising Promos
    {id = 898,  code = 'ZNR', is_promo_set = true },    --Zendikar Rising Promos
    {id = 897,  code = 'ZNR'},      --Zendikar Rising
    {id = 896,  code = 'PDOM'},     --Dominaria Promos
    {id = 896,  code = 'DOM', is_promo_set = true },    --Dominaria Promos
    {id = 895,  code = 'PRIX'},     --Rivals of Ixalan Promos
    {id = 894,  code = 'PXLN'},     --Ixalan Promos
    {id = 893,  code = 'JMP'},      --Jumpstart
    {id = 892,  code = '2XM'},      --Double Masters
    {id = 891,  code = 'M21'},      --Core Set 2021
    {id = 890,  code = 'OC20'},     --Commander 2020 (Oversized)
    {id = 890,  code = 'C20'},      --Commander 2020
    {id = 889,  code = 'IKO'},      --Ikoria: Lair of Behemoths
    {id = 888,  code = 'CMB1'},     --Mystery Booster Playtest Cards
    {id = 887,  code = 'SLD'},      --Secret Lair Drop Series
    {id = 886,  code = 'UND'},      --Unsanctioned
    {id = 885,  code = 'THB'},      --Theros: Beyond Death
    {id = 884,  code = 'GN2'},      --Game Night 2019
    {id = 883,  code = 'ELD'},      --Throne of Eldraine
    {id = 882,  code = 'OC19'},     --Commander 2019 (Oversized)
    {id = 882,  code = 'C19'},      --Commander 2019
    {id = 881,  code = 'M20'},      --Core Set 2020
    {id = 880,  code = 'SS2'},      --Signature Spellbook: Gideon
    {id = 879,  code = 'MH1'},      --Modern Horizons
    {id = 878,  code = 'WAR'},      --War of the Spark
    {id = 877,  code = 'G18'},      --Gift Pack 2018
    {id = 876,  code = 'GK2'},      --RNA Guild Kits
    {id = 875,  code = 'PRW2'},     --Ravnica Weekend Promos
    {id = 875,  code = 'PRWK'},     --Ravnica Weekend Promos
    {id = 874,  code = 'PUMA'},     --Ultimate Box Topper
    {id = 873,  code = 'RNA'},      --Ravnica Allegiance
    {id = 872,  code = 'UMA'},      --Ultimate Masters
    {id = 871,  code = 'GNT'},      --Game Night
    {id = 870,  code = 'GK1'},      --GRN Guild Kits
    {id = 869,  code = 'MED'},      --Guilds of Ravnica Mythic Edition
    {id = 868,  code = 'GRN'},      --Guilds of Ravnica
    {id = 867,  code = 'OC18'},     --Commander 2018 (Oversized)
    {id = 867,  code = 'C18'},      --Commander 2018
    {id = 866,  code = 'M19'},      --Magic 2019
    {id = 865,  code = 'GS1'},      --Global Series: Jiang Yanggu & Mu Yanling 
    {id = 864,  code = 'SS1'},      --Signature Spellbook: Jace
    {id = 863,  code = 'BBD'},      --Battlebond
    {id = 862,  code = 'CM2'},      --Commander Anthology 2
    {id = 861,  code = 'DOM'},      --Dominaria
    {id = 860,  code = 'DDU'},      --Duel Decks: Elves vs. Inventors
    {id = 859,  code = 'A25'},      --Masters 25
    {id = 858,  code = 'RIX'},      --Rivals of Ixalan
    {id = 857,  code = 'UST'},      --Unstable
    {id = 856,  code = 'V17'},      --From the Vault: Transform
    {id = 855,  code = 'E02'},      --Explorers of Ixalan
    {id = 854,  code = 'IMA'},      --Iconic Masters
    {id = 853,  code = 'DDT'},      --Duel Decks: Merfolk vs. Goblins
    {id = 852,  code = 'XLN'},      --Ixalan
    {id = 851,  code = 'OC17'},     --Commander 2017 (Oversized))
    {id = 851,  code = 'C17'},      --Commander 2017
    {id = 850,  code = 'HOU'},      --Hour of Devastation
    {id = 849,  code = 'OE01'},     --Archenemy: Nicol Bolas Schemes
    {id = 849,  code = 'E01'},      --Archenemy: Nicol Bolas
    {id = 848,  code = 'CMA'},      --Commander Anthology
    {id = 847,  code = 'DDS'},      --Duel Decks: Mind vs. Might
    {id = 846,  code = 'W17'},      --Welcome Deck 2017
    {id = 845,  code = 'MP2'},      --Amonkhet Invocations
    {id = 844,  code = 'AKH'},      --Amonkhet
    {id = 843,  code = 'MM3'},      --Modern Masters 2017 Edition
    {id = 842,  code = 'OPCA'},     --Planechase Anthology Planes
    {id = 842,  code = 'PCA'},      --Planechase Anthology
    {id = 841,  code = 'AER'},      --Aether Revolt
    {id = 840,  code = 'OC16'},     --Commander 2016 (Oversized)
    {id = 840,  code = 'C16'},      --Commander 2016
    {id = 839,  code = 'MPS'},      --Kaladesh Inventions
    {id = 838,  code = 'KLD'},      --Kaladesh
    {id = 837,  code = 'DDR'},      --Duel Decks: Nissa vs. Ob Nixilis
    {id = 836,  code = 'CN2'},      --Conspiracy: Take the Crown
    {id = 835,  code = 'V16'},      --From the Vault: Lore
    {id = 834,  code = 'EMN'},      --Eldritch Moon
    {id = 833,  code = 'EMA'},      --Eternal Masters
    {id = 832,  code = 'W16'},      --Welcome Deck 2016
    {id = 831,  code = 'SOI'},      --Shadows Over Innistrad
    {id = 830,  code = 'DDQ'},      --Duel Decks: Blessed vs. Cursed
    {id = 829,  code = 'OGW'},      --Oath of the Gatewatch
    {id = 828,  code = 'OC15'},     --Commander 2015 (Oversized)
    {id = 828,  code = 'C15'},      --Commander 2015
    {id = 827,  code = 'CP3'},      --Magic Origins Clash Pack
    {id = 826,  code = 'EXP'},      --Zendikar Expeditions
    {id = 825,  code = 'BFZ'},      --Battle for Zendikar
    {id = 824,  code = 'DDP'},      --Duel Decks: Zendikar vs. Eldrazi
    {id = 823,  code = 'V15'},      --From the Vault: Angels
    {id = 822,  code = 'ORI'},      --Magic Origins
    {id = 821,  code = 'TDAG'},     --Challenge Deck: Defeat a God
    {id = 820,  code = 'DDO'},      --Duel Decks: Elspeth vs. Kiora
    {id = 819,  code = 'MM2'},      --Modern Masters 2015
    {id = 818,  code = 'DTK'},      --Dragons of Tarkir
    {id = 817,  code = 'DVD'},      --Duel Decks: Anthology - Divine vs Demonic
    {id = 817,  code = 'EVG'},      --Duel Decks: Anthology - Elves vs Goblins
    {id = 817,  code = 'GVL'},      --Duel Decks: Anthology - Garruk vs Liliana
    {id = 817,  code = 'JVC'},      --Duel Decks: Anthology - Jace vs Chandra
    {id = 816,  code = 'FRF'},      --Fate Reforged
    {id = 815,  code = 'CP2'},      --Fat Reforged Clash Pack
    {id = 814,  code = 'OC14'},     --Commander 2014 (Oversized)
    {id = 814,  code = 'C14'},      --Commander 2014
    {id = 813,  code = 'KTK'},      --Khans of Tarkir
    {id = 812,  code = 'DDN'},      --Duel Decks: Speed vs. Cunning
    {id = 811,  code = 'CP1'},      --Magic 2015 Clash Pack
    {id = 810,  code = 'MD1'},      --Magic Modern Event Deck
    {id = 809,  code = 'V14'},      --From the Vault: Annihilation
    {id = 808,  code = 'M15'},      --Magic 2015
    {id = 807,  code = 'CNS'},      --Conspiracy
    {id = 806,  code = 'JOU'},      --Journey Into Nyx
    {id = 805,  code = 'DDM'},      --Duel Decks: Jace vs. Vraska
    {id = 804,  code = 'TBTH'},     --Challenge Deck: Battle the Horde
    {id = 803,  code = 'TFTH'},     --Challenge Deck: Face the Hydra
    {id = 802,  code = 'BNG'},      --Born of the Gods
    {id = 801,  code = 'OC13'},     --Commander 2013 (Oversized)
    {id = 801,  code = 'C13'},      --Commander 2013
    {id = 800,  code = 'THS'},      --Theros
    {id = 799,  code = 'DDL'},      --Duel Decks: Heroes vs. Monsters
    {id = 798,  code = 'V13'},      --From the Vault: Twenty
    {id = 797,  code = 'M14'},      --Magic 2014
    {id = 796,  code = 'MMA'},      --Modern Masters
    {id = 795,  code = 'DGM'},      --Dragon's Maze
    {id = 794,  code = 'DDK'},      --Duel Decks: Sorin vs. Tibalt
    {id = 793,  code = 'GTC'},      --Gatecrash
    {id = 792,  code = 'OCM1'},     --Commander's Arsenal (Oversized)
    {id = 792,  code = 'CM1'},      --Commander's Arsenal
    {id = 791,  code = 'RTR'},      --Return to Ravnica
    {id = 790,  code = 'DDJ'},      --Duel Decks: Izzet vs. Golgari
    {id = 789,  code = 'V12'},      --From the Vault: Realms
    {id = 788,  code = 'M13'},      --Magic 2013
    {id = 787,  code = 'OPC2'},     --Planechase 2012 Planes
    {id = 787,  code = 'PC2'},      --Planechase 2012
    {id = 786,  code = 'AVR'},      --Avacyn Restored
    {id = 785,  code = 'DDI'},      --Duel Decks: Venser vs. Koth
    {id = 784,  code = 'DKA'},      --Dark Ascension
    {id = 783,  code = 'PD3'},      --Premium Deck Series: Graveborn
    {id = 782,  code = 'ISD'},      --Innistrad
    {id = 781,  code = 'DDH'},      --Duel Decks: Ajani vs. Nicol Bolas
    {id = 780,  code = 'V11'},      --From the Vault: Legends
    {id = 779,  code = 'M12'},      --Magic 2012
    {id = 778,  code = 'OCMD'},     --Commander 2011 (Oversized)
    {id = 778,  code = 'CMD'},      --Commander 2011
    {id = 777,  code = 'DDG'},      --Duel Decks: Knights vs. Dragons
    {id = 776,  code = 'NPH'},      --New Phyrexia
    {id = 775,  code = 'MBS'},      --Mirrodin Besieged
    {id = 774,  code = 'PD2'},      --Premium Deck Series: Fire and Lightning
    {id = 773,  code = 'SOM'},      --Scars of Mirrodin
    {id = 772,  code = 'DDF'},      --Duel Decks: Elspeth vs. Tezzeret
    {id = 771,  code = 'V10'},      --From the Vault: Relics
    {id = 770,  code = 'M11'},      --Magic 2011
    {id = 769,  code = 'OARC'},     --Archenemy Schemes
    {id = 769,  code = 'ARC'},      --Archenemy
    {id = 768,  code = 'DPA'},      --Duels of the Planeswalkers
    {id = 767,  code = 'ROE'},      --Rise of the Eldrazi
    {id = 766,  code = 'DDE'},      --Duel Decks: Phyrexia vs. The Coalition
    {id = 765,  code = 'WWK'},      --Worldwake
    {id = 764,  code = 'H09'},      --Premium Deck Series: Slivers
    {id = 763,  code = 'DDD'},      --Duel Decks: Garruk vs. Liliana
    {id = 762,  code = 'ZEN'},      --Zendikar
    {id = 761,  code = 'OHOP'},     --Planechase Planes
    {id = 761,  code = 'HOP'},      --Planechase
    {id = 760,  code = 'V09'},      --From the Vault: Exiled
    {id = 759,  code = 'M10'},      --Magic 2010
    {id = 758,  code = 'ARB'},      --Alara Reborn
    {id = 757,  code = 'DDC'},      --Duel Decks: Divine vs. Demonic
    {id = 756,  code = 'CON'},      --Conflux
    {id = 755,  code = 'DD2'},      --Duel Decks: Jace vs. Chandra
    {id = 754,  code = 'ALA'},      --Shards of Alara
    {id = 753,  code = 'DRB'},      --From the Vault: Dragons
    {id = 752,  code = 'EVE'},      --Eventide
    {id = 751,  code = 'SHM'},      --Shadowmoor
    {id = 750,  code = 'MOR'},      --Morningtide
    {id = 740,  code = 'DD1'},      --Duel Decks: Elves vs. Goblins
    {id = 730,  code = 'LRW'},      --Lorwyn
    {id = 720,  code = '10E'},      --10th Edition
    {id = 720,  code = 'P15A'},     --10th Edition Promos
    {id = 710,  code = 'FUT'},      --Future Sight
    {id = 700,  code = 'PLC'},      --Planar Chaos
    {id = 690,  code = 'TSB'},      --Timeshifted
    {id = 680,  code = 'TSP'},      --Time Spiral
    {id = 675,  code = 'CST'},      --Coldsnap Theme Deck Reprints
    {id = 670,  code = 'CSP'},      --Coldsnap
    {id = 660,  code = 'DIS'},      --Dissension
    {id = 650,  code = 'GPT'},      --Guildpact
    {id = 640,  code = 'RAV'},      --Ravnica
  --{id =  636, code = 'PS11'},     --Salvat 2011
  --{id =  635, code = 'PSAL'},     --Salvat Magic Encyclopedia
    {id = 630,  code = '9ED'},      --9th Edition
    {id = 620,  code = 'SOK'},      --Saviors of Kamigawa
    {id = 610,  code = 'BOK'},      --Betrayers of Kamigawa
    {id = 600,  code = 'UNH'},      --Unhinged
    {id = 590,  code = 'CHK'},      --Champions of Kamigawa
    {id = 580,  code = '5DN'},      --Fifth Dawn
    {id = 570,  code = 'DST'},      --Darksteel
    {id = 560,  code = 'MRD'},      --Mirrodin
    {id = 550,  code = '8ED'},      --8th Edition
    {id = 540,  code = 'SCG'},      --Scourge
    {id = 530,  code = 'LGN'},      --Legions
    {id = 520,  code = 'ONS'},      --Onslaught
    {id = 510,  code = 'JUD'},      --Judgment
    {id = 500,  code = 'TOR'},      --Torment
    {id = 490,  code = 'DKM'},      --Deckmasters Garfield vs. Finkel
    {id = 480,  code = 'ODY'},      --Odyssey
    {id = 470,  code = 'APC'},      --Apocalypse
    {id = 460,  code = '7ED'},      --7th Edition
    {id = 450,  code = 'PLS'},      --Planeshift
    {id = 440,  code = 'BTD'},      --Beatdown Box Set
    {id = 430,  code = 'INV'},      --Invasion
    {id = 420,  code = 'PCY'},      --Prophecy
    {id = 415,  code = 'S00'},      --Starter 2000
    {id = 410,  code = 'NEM'},      --Nemesis
    {id = 405,  code = 'BRB'},      --Battle Royale Box Set
    {id = 400,  code = 'MMQ'},      --Mercadian Masques
    {id = 390,  code = 'O90P'},     --Starter 1999 (Oversized 90s Promos)
    {id = 390,  code = 'S99'},      --Starter 1999
    {id = 380,  code = 'PTK'},      --Portal Three Kingdoms
    {id = 370,  code = 'UDS'},      --Urza's Destiny
    {id = 360,  code = '6ED'},      --6th Edition
    {id = 350,  code = 'ULG'},      --Urza's Legacy
    {id = 340,  code = 'ATH'},      --Anthologies
    {id = 330,  code = 'USG'},      --Urza's Saga
    {id = 320,  code = 'UGL'},      --Unglued
    {id = 310,  code = 'P02'},      --Portal Second Age
    {id = 300,  code = 'EXO'},      --Exodus
    {id = 290,  code = 'STH'},      --Stronghold
    {id = 280,  code = 'TMP'},      --Tempest
    {id = 270,  code = 'WTH'},      --Weatherlight
    {id = 260,  code = 'POR'},      --Portal
    {id = 250,  code = '5ED'},      --5th Edition
    {id = 240,  code = 'VIS'},      --Visions
    {id = 235,  code = 'MGB'},      --Multiverse Gift Box
    {id = 230,  code = 'MIR'},      --Mirage
    {id = 225,  code = 'ITP'},      --Introductory Two-Player Set
    {id = 224,  code = 'RQS'},      --Rivals Quick Start Set
    {id = 220,  code = 'ALL'},      --Alliances
    {id = 210,  code = 'HML'},      --Homelands
    {id = 201,  code = 'RIN'},      --Renaissance (ITA)
    {id = 201,  code = 'REN'},      --Renaissance (FRA)
    {id = 200,  code = 'CHR'},      --Chronicles
    {id = 190,  code = 'ICE'},      --Ice Age
    {id = 180,  code = '4ED'},      --4th Edition
  --{id =  179, code = '4BB'},      --4th Edition (FBB)
    {id = 170,  code = 'FEM'},      --Fallen Empires
    {id = 160,  code = 'DRK'},      --The Dark
    {id = 150,  code = 'LEG'},      --Legends
    {id = 141,  code = 'SUM'},      --Revised Edition (Summer Magic)
    {id = 140,  code = '3ED'},      --Revised
  --{id =  139, code = 'FBB'},      --Revised Edition (FBB)
    {id = 130,  code = 'ATQ'},      --Antiquities
    {id = 120,  code = 'ARN'},      --Arabian Nights
    {id = 110,  code = '2ED'},      --Unlimited
    {id = 106,  code = 'CEI'},      --Collectors' Edition (International)
    {id = 105,  code = 'CED'},      --Collectors' Edition (Domestic)
    {id = 100,  code = 'LEB'},      --Beta
    {id = 90,   code = 'LEA'},      --Alpha
    {id = 89,   code = 'WC04'},     --2004 World Championship Decks
    {id = 88,   code = 'WC03'},     --2003 World Championship Decks
    {id = 87,   code = 'WC02'},     --2002 World Championship Decks
    {id = 86,   code = 'WC01'},     --2001 World Championship Decks
    {id = 85,   code = 'WC00'},     --2000 World Championship Decks
    {id = 84,   code = 'WC99'},     --1999 World Championship Decks
    {id = 83,   code = 'WC98'},	    --1998 World Championship Decks
    {id = 82,   code = 'WC97'},	    --1997 World Championship Decks
    {id = 81,   code = 'PTC'},	    --1996 Pro Tour Decks
    {id = 70,   code = 'PVAN'},     --Vanguard
  --{id = 69,   code = '???'},      --Box Topper Cards (Not on Scryfall)
    {id = 57,   code = 'PROMOS'},   --Planeswalker Weekend
    {id = 56,   code = 'SCH'},      --Store Championship Promos
    {id = 56,   code = 'PROMOS'},   --Store Championship Promos
    {id = 55,   code = 'UGIN'},     --Ugin's Fate Promos
    {id = 54,   code = 'PROMOS'},   --Draft Weekend Promos
    {id = 53,   code = 'PROMOS'},   --Holiday Gift Box Promos
    {id = 52,   code = 'PROMOS'},   --Intro Pack Promos
    {id = 51,   code = 'PROMOS'},   --Open House Promos
    {id = 50,   code = 'PXTC'},     --Buy-a-Box Promos (Ixalan Treasure Chest)
    {id = 50,   code = 'PROMOS'},   --Buy-a-Box Promos
    {id = 45,   code = 'PMPS11'},   --Magic Premiere Shop (2011)
    {id = 45,   code = 'PMPS10'},   --Magic Premiere Shop (2010)
    {id = 45,   code = 'PMPS09'},   --Magic Premiere Shop (2009)
    {id = 45,   code = 'PMPS08'},   --Magic Premiere Shop (2008)
    {id = 45,   code = 'PMPS07'},   --Magic Premiere Shop (2007)
    {id = 45,   code = 'PMPS06'},   --Magic Premiere Shop (2006)
    {id = 45,   code = 'PMPS'},     --Magic Premiere Shop (2005)
    {id = 43,   code = 'P2HG'},     --Two-Headed Giant Promos
    {id = 42,   code = 'P10E'},     --Summer of Magic Promos
    {id = 41,   code = 'HHO'},      --Happy Holidays Promos
    {id = 40,   code = 'PAL06'},    --Arena/Colosseo Leagues Promos (2006)
    {id = 40,   code = 'PAL05'},    --Arena/Colosseo Leagues Promos (2005)
    {id = 40,   code = 'PAL04'},    --Arena/Colosseo Leagues Promos (2004)
    {id = 40,   code = 'PAL03'},    --Arena/Colosseo Leagues Promos (2003)
    {id = 40,   code = 'PAL02'},    --Arena/Colosseo Leagues Promos (2002)
    {id = 40,   code = 'PAL01'},    --Arena/Colosseo Leagues Promos (2001)
    {id = 40,   code = 'PAL00'},    --Arena/Colosseo Leagues Promos (2000)
    {id = 40,   code = 'PAL99'},    --Arena/Colosseo Leagues Promos (1999)
    {id = 40,   code = 'PARL'},     --Arena/Colosseo Leagues Promos (1996)
    {id = 40,   code = 'OLEP'},     --Arena/Colosseo Leagues Promos (1996)
    {id = 40,   code = 'PROMOS'},   --Arena/Colosseo Leagues Promos (Magic League)
    {id = 34,   code = 'WMC'},      --World Magic Cup Qualifiers Promos
    {id = 33,   code = 'OLGC'},     --Championships Prizes (Legacy Championship)
    {id = 33,   code = 'OVNT'},     --Championships Prizes (Vintage Championship)
    {id = 33,   code = 'PWOR'},     --Championships Prizes
    {id = 32,   code = 'PPRO'},     --Pro Tour Promos
    {id = 31,   code = 'PGPX'},     --Grand Prix Promos
    {id = 30,   code = 'F18'},      --Friday Night Magic Promos (2018)
    {id = 30,   code = 'F17'},      --Friday Night Magic Promos (2017)
    {id = 30,   code = 'F16'},      --Friday Night Magic Promos (2016)
    {id = 30,   code = 'F15'},      --Friday Night Magic Promos (2015)
    {id = 30,   code = 'F14'},      --Friday Night Magic Promos (2014)
    {id = 30,   code = 'F13'},      --Friday Night Magic Promos (2013)
    {id = 30,   code = 'F12'},      --Friday Night Magic Promos (2012)
    {id = 30,   code = 'F11'},      --Friday Night Magic Promos (2011)
    {id = 30,   code = 'F10'},      --Friday Night Magic Promos (2010)
    {id = 30,   code = 'F09'},      --Friday Night Magic Promos (2009)
    {id = 30,   code = 'F08'},      --Friday Night Magic Promos (2008)
    {id = 30,   code = 'F07'},      --Friday Night Magic Promos (2007)
    {id = 30,   code = 'F06'},      --Friday Night Magic Promos (2006)
    {id = 30,   code = 'F05'},      --Friday Night Magic Promos (2005)
    {id = 30,   code = 'F04'},      --Friday Night Magic Promos (2004)
    {id = 30,   code = 'F03'},      --Friday Night Magic Promos (2003)
    {id = 30,   code = 'F02'},      --Friday Night Magic Promos (2002)
    {id = 30,   code = 'F01'},      --Friday Night Magic Promos (2001)
    {id = 30,   code = 'FNM'},      --Friday Night Magic Promos (2000)
    {id = 30,   code = 'PROMOS'},   --Friday Night Magic Promos
    {id = 28,   code = 'PSS4'},     --Standard Showdown Promos (MKM)
    {id = 28,   code = 'PSS3'},     --Standard Showdown Promos (M19)
    {id = 28,   code = 'PSS2'},     --Standard Showdown Promos (XLN)
    {id = 27,   code = 'PELP'},     --Alternate Art Lands (European Land Program)
    {id = 27,   code = 'PGRU'},     --Alternate Art Lands (Guru Lands)
    {id = 27,   code = 'PALP'},     --Alternate Art Lands (Asia Pacific Land Program)
    {id = 26,   code = 'GDY'},      --Game Day Promos
    {id = 26,   code = 'PW22'},     --Game Day Promos (WPN 2022)
    {id = 26,   code = 'PDCI'},     --Game Day Promos (DCI Promos)
    {id = 26,   code = 'THP3'},     --Game Day Promos (JOU Hero's Path)
    {id = 26,   code = 'THP2'},     --Game Day Promos (BNG Hero's Path)
    {id = 26,   code = 'THP1'},     --Game Day Promos (THS Hero's Path)
    {id = 26,   code = 'P10E'},     --Game Day Promos (Tenth Edition Promos)
    {id = 26,   code = 'PROMOS'},   --Game Day Promos
    {id = 25,   code = 'P22'},      --Judge Gift Cards (2022)
    {id = 25,   code = 'PJ21'},     --Judge Gift Cards (2021)
    {id = 25,   code = 'J20'},      --Judge Gift Cards (2020)
    {id = 25,   code = 'J19'},      --Judge Gift Cards (2019)
    {id = 25,   code = 'J18'},      --Judge Gift Cards (2018)
    {id = 25,   code = 'J17'},      --Judge Gift Cards (2017)
    {id = 25,   code = 'J16'},      --Judge Gift Cards (2016)
    {id = 25,   code = 'J15'},      --Judge Gift Cards (2015)
    {id = 25,   code = 'J14'},      --Judge Gift Cards (2014)
    {id = 25,   code = 'J13'},      --Judge Gift Cards (2013)
    {id = 25,   code = 'J12'},      --Judge Gift Cards (2012)
    {id = 25,   code = 'G11'},      --Judge Gift Cards (2011)
    {id = 25,   code = 'G10'},      --Judge Gift Cards (2010)
    {id = 25,   code = 'G09'},      --Judge Gift Cards (2009)
    {id = 25,   code = 'G08'},      --Judge Gift Cards (2008)
    {id = 25,   code = 'G07'},      --Judge Gift Cards (2007)
    {id = 25,   code = 'G06'},      --Judge Gift Cards (2006)
    {id = 25,   code = 'G05'},      --Judge Gift Cards (2005)
    {id = 25,   code = 'G04'},      --Judge Gift Cards (2004)
    {id = 25,   code = 'G03'},      --Judge Gift Cards (2003)
    {id = 25,   code = 'G02'},      --Judge Gift Cards (2002)
    {id = 25,   code = 'G01'},      --Judge Gift Cards (2001)
    {id = 25,   code = 'G00'},      --Judge Gift Cards (2000)
    {id = 25,   code = 'G99'},      --Judge Gift Cards (1999)
    {id = 25,   code = 'JGP'},      --Judge Gift Cards (1998)
    {id = 24,   code = 'PCMP'},     --Champs Promos
    {id = 23,   code = 'PW24'},     --Gateway & WPN Promos (2024)
    {id = 23,   code = 'PW23'},     --Gateway & WPN Promos (2023)
    {id = 23,   code = 'PW22'},     --Gateway & WPN Promos (2022)
    {id = 23,   code = 'PW21'},     --Gateway & WPN Promos (2021)
    {id = 23,   code = 'PW12'},     --Gateway & WPN Promos (2012)
    {id = 23,   code = 'PW11'},     --Gateway & WPN Promos (2011)
    {id = 23,   code = 'PDCI'},     --Gateway & WPN Promos (DCI Promos)
    {id = 22,   code = 'PDCI'},     --Prerelease Promos (DCI Promos)
    {id = 22,   code = 'PTKDF'},    --Prerelease Promos (Tarkir Dragonfury)
    {id = 22,   code = 'PPC1'},     --Prerelease Promos (M15 Prerelease Challenge)
    {id = 22,   code = 'THP3'},     --Prerelease Promos (JOU Hero's Path)
    {id = 22,   code = 'THP2'},     --Prerelease Promos (BNG Hero's Path)
    {id = 22,   code = 'THP1'},     --Prerelease Promos (THS Hero's Path)
    {id = 22,   code = 'PHEL'},     --Prerelease Promos (Open the Helvault)
    {id = 22,   code = 'PROMOS'},   --Prerelease Promos
    {id = 21,   code = 'PDCI'},     --Release & Launch Parties Promos (DCI Promos)
    {id = 21,   code = 'PHOP'},     --Release & Launch Parties Promos (Planechase Promos)
    {id = 21,   code = 'THP3'},     --Release & Launch Parties Promos (JOU Hero's Path)
    {id = 21,   code = 'THP2'},     --Release & Launch Parties Promos (BNG Hero's Path)
    {id = 21,   code = 'THP1'},     --Release & Launch Parties Promos (THS Hero's Path)
    {id = 21,   code = 'PCMD'},     --Release & Launch Parties Promos (CMD Release)
    {id = 21,   code = 'O90P'},     --Release & Launch Parties Promos (Oversized 90s Promos)
    {id = 21,   code = 'PROMOS'},   --Release & Launch Parties Promos
    {id = 20,   code = 'P11'},      --Magic Player Rewards (2011)
    {id = 20,   code = 'P10'},      --Magic Player Rewards (2010)
    {id = 20,   code = 'P09'},      --Magic Player Rewards (2009)
    {id = 20,   code = 'P08'},      --Magic Player Rewards (2008)
    {id = 20,   code = 'P07'},      --Magic Player Rewards (2007)
    {id = 20,   code = 'P06'},      --Magic Player Rewards (2006)
    {id = 20,   code = 'P05'},      --Magic Player Rewards (2005)
    {id = 20,   code = 'P04'},      --Magic Player Rewards (2004)
    {id = 20,   code = 'P03'},      --Magic Player Rewards (2003)
    {id = 20,   code = 'PR2'},      --Magic Player Rewards (2002)
    {id = 20,   code = 'MPR'},      --Magic Player Rewards (2001)
    {id = 15,   code = 'PS19'},     --Convention Promos (San Diego Comic-Con 2019)
    {id = 15,   code = 'PS18'},     --Convention Promos (San Diego Comic-Con 2018)
    {id = 15,   code = 'PS17'},     --Convention Promos (San Diego Comic-Con 2017)
    {id = 15,   code = 'PS16'},     --Convention Promos (San Diego Comic-Con 2016)
    {id = 15,   code = 'PS15'},     --Convention Promos (San Diego Comic-Con 2015)
    {id = 15,   code = 'PS14'},     --Convention Promos (San Diego Comic-Con 2014)
    {id = 15,   code = 'PSDC'},     --Convention Promos (San Diego Comic-Con 2013)
    {id = 15,   code = 'H17'},      --Convention Promos (HasCon 2017)
    {id = 15,   code = 'P15A'},     --Convention Promos (15th Anniversary Cards)
    {id = 15,   code = 'O90P'},     --Convention Promos (Oversized 90s Promos)
    {id = 15,   code = 'PURL'},     --Convention Promos (URL Promos)
    {id = 15,   code = 'PROMOS'},   --Convention Promos
    {id = 12,   code = 'PHJ'},      --Hobby Japan Commemorative Cards
    {id = 11,   code = 'PRED'},     --Redemption Program Cards
    {id = 10,   code = 'PJAS'},     --Junior Series Promos (Junior APAC Series)
    {id = 10,   code = 'PJSE'},     --Junior Series Promos (Junior Series Europe)
    {id = 10,   code = 'PSUS'},     --Junior Series Promos (Junior Super Series)
    {id = 9,    code = 'PDP15'},    --Video Game Promos
    {id = 9,    code = 'PDP14'},    --Video Game Promos
    {id = 9,    code = 'PDP13'},    --Video Game Promos
    {id = 9,    code = 'PDP12'},    --Video Game Promos
    {id = 9,    code = 'PDP10'},    --Video Game Promos
    {id = 9,    code = 'PDTP'},     --Video Game Promos
    {id = 9,    code = 'PMIC'},     --Video Game Promos
    {id = 8,    code = 'PWOS'},     --Stores Promos
    {id = 8,    code = 'PRES'},     --Stores Promos
    {id = 7,    code = 'O90P'},     --Magazine Inserts (Oversized 90s Promos)
    {id = 7,    code = 'PDRC'},     --Magazine Inserts
    {id = 7,    code = 'PMEI'},     --Magazine Inserts
    {id = 6,    code = 'O90P'},     --Comic Inserts (Oversized 90s Promos)
    {id = 6,    code = 'PIDW'},     --Comic Inserts
    {id = 6,    code = 'PMEI'},     --Comic Inserts
    {id = 5,    code = 'PBOOK'},    --Book Inserts
    {id = 5,    code = 'PHPR'},     --Book Inserts
    {id = 2,    code = 'PLGM'}      --DCI Legend Membership Promos
}

--[[ Lookup table to hold options needed to process promo sets
    Sets with code=PROMOS will look here for further params
    MA (up to KTK) categorized promos by their place of distribution, Scryfall categorizes many as "set
    promos" and keeps them in sets corresponding to their non-promo set codes; in order to recombine
    these in MA, we need some extra processing and filtering
    key         the set's id from MA
    type        string to look for in scryfall data's promo_types to see if a card should be included
    sets        the product-specific promo sets that are needed to get all the cards
    more_sets   any non-promo sets needed to get the rest of the cards
    whitelist   specific cards to include for the set (set_code => { collector_number = true, ... })
--]]
promo_sets = {
    -- Convention Promos
    [15] = {
        type = 'convention',
        sets = {'PXLN', 'PM19', 'PM20'},
    },
    -- Release & Launch Parties Promos
    [21] = {
        type = 'release',
        sets = {
            'P8ED', 'PUNH', 'PBOK', 'PSOK', 'P9ED', 'PRAV', 'PGPT', 'PDIS', 'PCSP', 'PTSP',
            'PPLC', 'PFUT', 'PLRW', 'PMOR', 'PSHM', 'PEVE', 'PCON', 'PARB', 'PM10', 'PZEN',
            'PWWK', 'PROE', 'PM11', 'PSOM', 'PMBS', 'PNPH', 'PM12', 'PISD', 'PDKA', 'PAVR',
            'PM13', 'PRTR', 'PGTC', 'PDGM', 'PM14', 'PTHS', 'PBNG', 'PJOU', 'PCNS', 'PM15',
            'PKTK', 'PFRF', 'PDTK', 'PORI', 'PBFZ', 'POGW', 'PSOI', 'PEMN', 'PKLD', 'PAER',
            'PAKH', 'PUST'
        },
        more_sets = {'J22'},
        whitelist = {
            ['PUST'] = { ['108'] = true }, -- Earl of Squirrel
        },
    },
    -- Prerelease Promos
    [22] = {
        type = 'prerelease',
        sets = {
            'PTMP', 'PSTH', 'PEXO', 'PUSG', 'PULG', 'PPTK', 'PUDS', 'PMMQ', 'PNEM', 'PPCY',
            'PINV', 'PPLS', 'PAPC', 'PODY', 'PTOR', 'PJUD', 'PONS', 'PLGN', 'PSCG', 'P8ED',
            'PMRD', 'PDST', 'P5DN', 'PCHK', 'PBOK', 'PSOK', 'P9ED', 'PRAV', 'PGPT', 'PDIS',
            'PCSP', 'PTSP', 'PPLC', 'PFUT', 'P10E', 'PLRW', 'PMOR', 'PSHM', 'PEVE', 'PALA',
            'PCON', 'PARB', 'PM10', 'PZEN', 'PWWK', 'PROE', 'PM11', 'PSOM', 'PMBS', 'PNPH',
            'PM12', 'PISD', 'PDKA', 'PAVR', 'PM13', 'PRTR', 'PGTC', 'PDGM', 'PM14', 'PTHS',
            'PBNG', 'PJOU', 'PM15', 'PMH1',
            -- the following sets have randomized prerelease cards and should eventually
            -- be moved to their own promo sets
            'PKTK', 'PDTK', 'PORI', 'POGW', 'PSOI', 'PEMN', 'PKLD', 'PHOU'
        },
        more_sets = {'MOC'},
        whitelist = {
            ['PKTK'] = { ['210p'] = true }, -- Utter End [P]
        },
    },
    -- Game Day Promos
    [26] = {
        type = 'gameday',
        sets = {
            'PMBS', 'PNPH', 'PISD', 'PDKA', 'PAVR', 'PM13', 'PRTR', 'PGTC', 'PDGM', 'PM14',
            'PTHS', 'PBNG', 'PJOU', 'PM15', 'PKTK', 'PFRF', 'PDTK', 'PORI', 'PBFZ', 'POGW',
            'PSOI', 'PEMN', 'PKLD', 'PAER', 'PAKH', 'PHOU'
        },
    },
    -- FNM Promos
    [30] = {
        type = 'fnm',
        sets = {'PDOM', 'PM19', 'PGRN', 'PRNA', 'PWAR'},
    },
    -- Arena/Colosseo Leagues Promos
    [40] = {
        type = 'league',
        sets = {'PXLN', 'PRIX', 'PDOM', 'PM19', 'PGRN', 'PRNA'},
    },
    -- Buy-a-Box Promos
    [50] = {
        type = 'buyabox',
        sets = {
            'PM10', 'PZEN', 'PWWK', 'PROE', 'PM11', 'PSOM', 'PMBS', 'PNPH', 'PM12', 'PISD',
            'PDKA', 'PAVR', 'PM13', 'PRTR', 'PGTC', 'PDGM', 'PM14', 'PTHS', 'PBNG', 'PJOU',
            'PM15', 'PKTK', 'PFRF', 'PDTK', 'PORI', 'PBFZ', 'POGW', 'PSOI', 'PEMN', 'PKLD',
            'PAER', 'PAKH', 'PHOU', 'PXLN', 'PUST', 'PRIX'
        },
        more_sets = {'MH1'},
    },
    -- Open House Promos
    [51] = {
        type = 'openhouse',
        sets = {'PXLN', 'PRIX', 'PDOM', 'PM19', 'PRNA', 'PGRN', 'PWAR'},
    },
    -- Intro Pack Promos
    [52] = {
        type = 'intropack',
        sets = {'PKTK', 'PFRF', 'PDTK', 'PORI', 'PBFZ', 'POGW', 'PSOI', 'PEMN'},
    },
    -- Holiday Gift Box Promos
    [53] = {
        type = 'giftbox',
        sets = {'PRTR', 'PTHS', 'PKTK', 'PBFZ', 'PSOI', 'PKLD'},
    },
    -- Draft Weekend Promos
    [54] = {
        type = 'draftweekend',
        sets = {'PHOU', 'PXLN', 'PRIX', 'PDOM', 'PM19', 'PGRN', 'PRNA', 'PWAR'},
    },
    -- Store Championship Promos
    [56] = {
        type = 'storechampionship',
        sets = {'PRIX', 'PDOM', 'PM19', 'PGRN', 'PRNA'},
    },
    -- Planeswalker Weekend Promos
    [57] = {
        type = 'instore',
        sets = {'PWAR'},
    },
}

-- MA's object types
CARD_OBJECT    = 1
TOKEN_OBJECT   = 2
NONTRAD_OBJECT = 3
INSERT_OBJECT  = 4
REPLICA_OBJECT = 5

--MA's language IDs
ENG_ID = 1
RUS_ID = 2
GER_ID = 3
FRA_ID = 4
ITA_ID = 5
POR_ID = 6
SPA_ID = 7
JPN_ID = 8
ZHC_ID = 9
ZHT_ID = 10
KOR_ID = 11
HEB_ID = 12
ARA_ID = 13
LAT_ID = 14
SAN_ID = 15
GRC_ID = 16
PHY_ID = 17
ELV_ID = 18

-- language code => lang_id lookup table
lang_lkup = {
    ['en']  = ENG_ID,
    ['ru']  = RUS_ID,
    ['de']  = GER_ID,
    ['fr']  = FRA_ID,
    ['it']  = ITA_ID,
    ['pt']  = POR_ID,
    ['es']  = SPA_ID,
    ['ja']  = JPN_ID,
    ['zhs'] = ZHC_ID,
    ['zht'] = ZHT_ID,
    ['ko']  = KOR_ID,
    ['he']  = HEB_ID,
    ['ar']  = ARA_ID,
    ['la']  = LAT_ID,
    ['sa']  = SAN_ID,
    ['grc'] = GRC_ID,
    ['ph']  = PHY_ID,
    ['??']  = ELV_ID,
}

-- Lookup table that defines a replacement list for card names
name_replace = {
    -- MA typo, report as db error
    ['Chaotic Aether']                 = 'Chaotic Æther',
    ['The Aether Flues']               = 'The Æther Flues',
    -- Universes Within cards that have not updated in MA yet
    ['Enkira, Hostile Scavenger']      = 'Michonne, Ruthless Survivor',
    ["Gisa's Favorite Shovel"]         = 'Lucille',
    ['Gregor, Shrewd Magistrate']      = 'Glenn, the Voice of Calm',
    ["Greymond, Avacyn's Stalwart"]    = 'Rick, Steadfast Leader',
    ['Hansk, Slayer Zealot']           = 'Daryl, Hunter of Walkers',
    ['Aisha of Sparks and Smoke']      = 'Ken, Burning Brawler',
    ['Immard, the Stormcleaver']       = 'Guile, Sonic Soldier',
    ['Maarika, Brutal Gladiator']      = 'Zangief, the Red Cyclone',
    ['Tadeas, Juniper Ascendant']      = 'Dhalsim, Pliable Pacifist',
    ['The Howling Abomination']        = 'Blanka, Ferocious Friend',
    ['Vikya, Scorching Stalwart']      = 'Ryu, World Warrior',
    ['Zethi, Arcane Blademaster']      = 'Chun-Li, Countless Kicks',
    -- TODO: report these?
    ['_____ Bird Gets the Worm']       = '________ Bird Gets the Worm',
    ['Knight in _____ Armor']          = 'Knight in ________ Armor',
    ['Make a _____ Splash']            = 'Make a ________ Splash',
    ['Wizards of the _____']           = 'Wizards of the ________',
    ['Last Voyage of the _____']       = 'Last Voyage of the ________',
    ['Wolf in _____ Clothing']         = 'Wolf in ________ Clothing',
    ['_____ Balls of Fire']            = '________ Balls of Fire',
    ['_____ Goblin']                   = '________ Goblin',
    ['Fight the _____ Fight']          = 'Fight the ________ Fight',
    ['_____-o-saurus']                 = '________-o-saurus',
    ['_____ _____ Rocketship']         = '______ ______ Rocketship',
    -- MA needs curly quotes instead of straight
    ['"Ach! Hans, Run!"']              = '“Ach! Hans, Run!”',
    ['"Rumors of My Death . . ."']     = '“Rumors of My Death . . .”',
    ['Kongming, "Sleeping Dragon"']    = 'Kongming, “Sleeping Dragon”',
    ['Pang Tong, "Young Phoenix"']     = 'Pang Tong, “Young Phoenix”',
    ['Henzie "Toolbox" Torre']         = 'Henzie “Toolbox” Torre',
    ['"Brims" Barone, Midway Mobster'] = '”Brims” Barone, Midway Mobster',
    ['"Lifetime" Pass Holder']         = '”Lifetime” Pass Holder',
    ['Meet and Greet "Sisay"']         = 'Meet and Greet “Sisay”',
    -- Colon-like modifier character coming from Scryfall, MA expects a normal colon
    ['Ratonhnhaké꞉ton']                = 'Ratonhnhaké:ton',
    -- MA expects meld cards to be formatted like DFCs
    ['Bruna, the Fading Light']        = 'Bruna, the Fading Light|Brisela, Voice of Nightmares',
    ['Gisela, the Broken Blade']       = 'Gisela, the Broken Blade|Brisela, Voice of Nightmares',
    ['Graf Rats']                      = 'Graf Rats|Chittering Host',
    ['Hanweir Battlements']            = 'Hanweir Battlements|Hanweir, the Writhing Township',
    ['Hanweir Garrison']               = 'Hanweir Garrison|Hanweir, the Writhing Township',
    ['Midnight Scavengers']            = 'Midnight Scavengers|Chittering Host',
    ['Argoth, Sanctum of Nature']      = 'Argoth, Sanctum of Nature|Titania, Gaea Incarnate',
    ['Mishra, Claimed by Gix']         = 'Mishra, Claimed by Gix|Mishra, Lost to Phyrexia',
    ['Phyrexian Dragon Engine']        = 'Phyrexian Dragon Engine|Mishra, Lost to Phyrexia',
    ['The Mightstone and Weakstone']   = 'The Mightstone and Weakstone|Urza, Planeswalker',
    ['Titania, Voice of Gaea']         = 'Titania, Voice of Gaea|Titania, Gaea Incarnate',
    ['Urza, Lord Protector']           = 'Urza, Lord Protector|Urza, Planeswalker',
    -- MA does not expect these to be formatted as split cards
    ['Curse of the Fire Penguin|Curse of the Fire Penguin Creature'] = 'Curse of the Fire Penguin',
    ['Blightsteel Colossus|Blightsteel Colossus']                    = 'Blightsteel Colossus',
    ['Darksteel Colossus|Darksteel Colossus']                        = 'Darksteel Colossus',
    ['Doubling Cube|Doubling Cube']                                  = 'Doubling Cube',
    ['Etali, Primal Storm|Etali, Primal Storm']                      = 'Etali, Primal Storm',
    ['Ghalta, Primal Hunger|Ghalta, Primal Hunger']                  = 'Ghalta, Primal Hunger',
    ['Ulamog, the Ceaseless Hunger|Ulamog, the Ceaseless Hunger']    = 'Ulamog, the Ceaseless Hunger',
}

-- Lookup table to manually override card attributes (version_lookup should be preferred to set card.ver)
card_hacks = {
    -- lord of the rings commander
    ['LTC'] = {
        -- these should be replicas
        ['81'] = { obj_type = CARD_OBJECT },
        ['82'] = { obj_type = CARD_OBJECT },
        ['83'] = { obj_type = CARD_OBJECT },
        ['84'] = { obj_type = CARD_OBJECT },
        -- Scryfall doesn't have an Elven language, so need to set it manually
        ['408'] = { lang_id = ELV_ID },
        ['409'] = { lang_id = ELV_ID },
        ['410'] = { lang_id = ELV_ID },
    },
    -- lord of the rings
    ['LTR'] = {
        -- see comment for 408-410 in LTC
        ['0'] = { lang_id = ELV_ID },
    },
    -- m15 prerelease challenge
    ['PPC1'] = {
        ['1'] = { obj_type = NONTRAD_OBJECT },
    },
    -- the list: unfinity
    ['ULST'] = {
        ['37'] = { name = 'Ineffable Blessing (c)' },
        ['38'] = { name = 'Ineffable Blessing (a)' },
        ['55'] = { name = 'Everythingamajig (a)' },
        ['56'] = { name = 'Everythingamajig (f)' },
    },
}

--[[ Lookup table of functions used to set a card's version within a specific set code
    key     the set code from Scryfall
    func    Takes a card record as a param; returns the card's version as a string ~or~
            returns nil to use default version processing present in parse_card
            NOTE: May also set the append_ver param in the card object
--]]
version_lookup = {
    ['2X2'] = function(card)
        if is_between(card.data.cnum, 413, 572) then return 'Etched' end
        if is_between(card.data.cnum, 578, 579) then return 'Promo' end
    end,
    ['2XM'] = function(card)
        if card.data.cnum == 334 then return 'Ext Art' end
    end,
    ['40K'] = function(card)
        if is_between(card.data.cnum, 177, 180) then return 'Display Surge' end
        if is_between(card.data.cnum, 318, 321) then return 'Display Etched' end
        if card.data.cnum == 322 then return 'Promo' end
        if card.data.collector_number:match('★') then return '' end
    end,
    ['ACR'] = function(card)
        if is_between(card.data.cnum, 111, 116) then return 'Scene' end
    end,
    ['BBD'] = function(card)
        if is_between(card.data.cnum, 255, 256) then return 'Alt Art' end
    end,
    ['BFZ'] = function(card)
        if is_between(card.data.cnum, 250, 274) and card.data.full_art then
            card.append_ver = true
            return '#F'
        end
    end,
    ['BLB'] = function(card)
        if
            card.data.cnum == 293 or
            card.data.cnum == 342 or
            is_between(card.data.cnum, 337, 340)
        then
            card.append_ver = true
            return 'Alt Art #'
        end
        if is_between(card.data.cnum, 282, 294) then return 'Alt Art' end
        if is_between(card.data.cnum, 343, 355) then return 'Raised Foil' end
    end,
    ['BLC'] = function(card)
        if is_between(card.data.cnum, 1, 4) then return '' end
        if is_between(card.data.cnum, 93, 96) or is_between(card.data.cnum, 101, 104) then return 'Raised Foil' end
    end,
    ['BRR'] = function(card)
        if card.data.cnum >= 64 then return 'Schematic' end
    end,
    ['CHK'] = function(card)
        if card.data.cnum == 160 then return card.data.collector_number:gsub('%d','') end
    end,
    ['CLU'] = function(card)
        if is_between(card.data.cnum, 1, 21) or is_between(card.data.cnum, 274, 283) then return '' end
        if card.data.cnum == 284 then return 'Promo' end
    end,
    ['CMM'] = function(card)
        if card.data.cnum == 686 then return 'Alt Art' end
        if card.data.cnum == 1067 then return 'Promo' end
    end,
    ['CMR'] = function(card)
        if card.data.cnum == 721 then return '' end
        --if card.data.cnum == 722 then return 'Promo' end
    end,
    ['CN2'] = function(card)
        if card.data.cnum == 222 then return 'Alt' end
    end,
    ['DBL'] = function(card)
        if includes({171, 199, 261}, card.data.cnum) then return 'MID' end
        if includes({455, 486, 530}, card.data.cnum) then return 'VOW' end
        if card.data.cnum == 535 then return '' end
    end,
    ['DKM'] = function(card)
        if card.data.cnum == 14 or card.data.cnum == 36 then
            if includes(card.data.finishes, 'nonfoil') then
                return '1'
            else
                return '2'
            end
        end
    end,
    ['DMR'] = function(card)
        if is_between(card.data.cnum, 262, 401) then return 'Retro' end
        if card.data.cnum == 457 then return 'Promo' end
    end,
    ['DMU'] = function(card)
        if is_between(card.data.cnum, 369, 370) then return 'Phyrexian' end
        if card.data.cnum == 371 then return 'Phy Art' end
        if card.data.cnum == 375 then return 'Alt Art 1' end
        if card.data.cnum == 376 then return 'Alt Art 2' end
    end,
    ['DOM'] = function(card)
        if card.data.cnum == 280 then return '' end
    end,
    ['DSC'] = function(card)
        if is_between(card.data.cnum, 1, 8) or is_between(card.data.cnum, 368, 373) then return '' end
    end,
    ['DSK'] = function(card)
        if is_between(card.data.cnum, 287, 301) then return 'Lurking Evil' end
        if is_between(card.data.cnum, 351, 367) then return 'Double Exposure' end
        if is_between(card.data.cnum, 386, 395) then return 'Japanese Showcase' end
        if is_between(card.data.cnum, 396, 405) then return 'Fracture Foil' end
    end,
    ['DVD'] = function(card)
        if
            is_between(card.data.cnum, 26, 29) or
            is_between(card.data.cnum, 59, 62)
        then card.append_ver = true end
        return 'DVD'
    end,
    ['ELD'] = function(card)
        if is_between(card.data.cnum, 270, 272) then return 'Ext Art' end
        if card.data.cnum == 303 then return '' end
        if card.data.cnum == 392 then return 'Bundle' end
        if is_between(card.data.cnum, 393, 397) then return '' end
    end,
    ['EVG'] = function(card)
        if
            is_between(card.data.cnum, 28, 31) or
            is_between(card.data.cnum, 59, 62)
        then card.append_ver = true end
        return 'EVG'
    end,
    ['F06'] = function(card)
        if card.data.cnum == 5 then return '2006' end
    end,
    ['F16'] = function(card)
        if card.data.cnum == 5 then return '2016' end
    end,
    ['G00'] = function(card)
        if card.data.cnum == 2 then return '2000' end
    end,
    ['G07'] = function(card)
        if card.data.cnum == 4 then return '2007' end
    end,
    ['G10'] = function(card)
        if card.data.cnum == 8 then return '2010' end
    end,
    ['GRN'] = function(card)
        if card.data.cnum == 273 then return '' end
    end,
    ['GVL'] = function(card)
        if
            is_between(card.data.cnum, 28, 31) or
            is_between(card.data.cnum, 60, 63)
        then card.append_ver = true end
        return 'GVL'
    end,
    ['H17'] = function() return 'Hascon 17' end,
    ['IKO'] = function(card)
        if card.data.cnum == 275 then return '' end
        if is_between(card.data.cnum, 276, 278) then return 'Showcase' end
        if card.data.cnum == 364 then return 'Bundle' end
    end,
    ['J13'] = function(card)
        if card.data.cnum == 7 then return '2013' end
    end,
    ['J15'] = function(card)
        if card.data.cnum == 8 then return '2015' end
    end,
    ['J18'] = function(card)
        if card.data.cnum == 2 then return '2018' end
    end,
    ['J22'] = function(card)
        if includes({59, 73, 74, 76, 613}, card.data.cnum) then return 'Alt Art' end
        if card.data.cnum == 835 then return 'Promo' end
    end,
    ['JMP'] = function(card)
        if card.data.cnum == 496 then return 'Promo' end
    end,
    ['JVC'] = function(card)
        if
            is_between(card.data.cnum, 30, 33) or
            is_between(card.data.cnum, 59, 62)
        then card.append_ver = true end
        return 'JVC'
    end,
    ['LCC'] = function(card)
        if card.data.cnum == 20 then return 'Showcase' end
        if card.data.cnum == 104 then return 'Alt Art' end
        if is_between(card.data.cnum, 101, 120) then return '' end
    end,
    ['LCI'] = function(card)
        if card.data.cnum == 307 then return 'Showcase' end
    end,
    ['LTC'] = function(card)
        if is_between(card.data.cnum, 81, 84) then return 'Etched' end
        if is_between(card.data.cnum, 348, 377) or is_between(card.data.cnum, 491, 534) then return '' end
    end,
    ['LTR'] = function(card)
        if card.data.cnum == 0 then return '1 of 1' end
        if card.data.cnum == 301 then return 'Promo' end
        if is_between(card.data.cnum, 302, 331) then return 'Ring' end
        if card.data.cnum == 343 then return 'Alt Art 1' end
        if is_between(card.data.cnum, 405, 447) then return 'Scene' end
        if is_between(card.data.cnum, 713, 722) then card.append_ver = true end
        if card.data.cnum == 750 then return 'Alt Art 2' end
        if card.name == 'Nazgûl' then return '0' .. card.data.collector_number end
    end,
    ['M19'] = function(card)
        if card.data.cnum == 306 then return '' end
    end,
    ['M20'] = function(card)
        if card.data.cnum == 281 then return '' end
    end,
    ['M21'] = function(card)
        if is_between(card.data.cnum, 275, 277) then
            card.append_ver = true
            return 'Alt Art'
        end
        if card.data.cnum == 278 then return '' end
        if is_between(card.data.cnum, 279, 282) or card.data.cnum == 284 then return 'Ext Art' end
        if is_between(card.data.cnum, 290, 293) then card.append_ver = true end
    end,
    ['M3C'] = function(card)
        if is_between(card.data.cnum, 148, 151) then return 'Display Ripple' end
    end,
    ['MAT'] = function(card)
        if card.data.cnum >= 229 and card.data.cnum <= 230 then return 'Promo' end
    end,
    ['MED'] = function(card)
        if card.data.collector_number:match('WS') then return 'WAR' end
        if card.data.collector_number:match('RA') then return 'RNA' end
        if card.data.collector_number:match('GR') then return 'GRN' end
    end,
    ['MH2'] = function(card)
        if is_between(card.data.cnum, 327, 380) then return 'Sketch' end
        if is_between(card.data.cnum, 381, 441) then return 'Retro' end
    end,
    ['MH3'] = function(card)
        if is_between(card.data.cnum, 384, 441) then return 'Retro' end
        if is_between(card.data.cnum, 442, 446) then return 'Alt Art' end
        if is_between(card.data.cnum, 495, 496) then return 'Promo' end
    end,
    ['MKC'] = function(card)
        if is_between(card.data.cnum, 355, 358) then card.append_ver = true end
    end,
    ['MOC'] = function(card)
        if is_between(card.data.cnum, 448, 450) then return 'Showcase' end
    end,
    ['MOM'] = function(card)
        if includes(card.data.promo_types, 'doublerainbow') then return 'Alt Art' end
    end,
    ['MP2'] = function() return '' end,
    ['MUL'] = function(card)
        if is_between(card.data.cnum, 66, 130) then return 'Etched' end
        if includes(card.data.promo_types, 'doublerainbow') then return 'Rainbow' end
    end,
    ['NEO'] = function(card)
        if is_between(card.data.cnum, 307, 308) then return 'Phyrexia' end
        if card.data.cnum == 429 then return 'Red' end
        if card.data.cnum == 430 then return 'Green' end
        if card.data.cnum == 431 then return 'Blue' end
        if card.data.cnum == 432 then return 'Yellow' end
    end,
    ['OC20'] = function() return 'Display' end,
    ['OGW'] = function(card)
        if is_between(card.data.cnum, 183, 184) and card.data.full_art then
            card.append_ver = true
            return '#F'
        end
    end,
    ['OLEP'] = function(card)
        if includes({8, 13, 18, 23, 29, 34, 39, 44, 49, 54, 59, 65, 71, 76, 81}, card.data.cnum) then return '3rd' end
        if includes({9, 14, 19, 24, 30, 35, 40, 45, 50, 55, 60, 66, 72, 77, 82}, card.data.cnum) then return '4th' end
    end,
    ['OLGC'] = function(card)

    end,
    ['ONE'] = function(card)
        if is_between(card.data.cnum, 325, 329) then return '' end
        if is_between(card.data.cnum, 330, 344) then return 'Alt Art' end
        if card.data.cnum == 414 then return '' end
        if
            is_between(card.data.cnum, 415, 416) or
            is_between(card.data.cnum, 418, 421)
        then return card.data.collector_number end
    end,
    ['OTC'] = function(card)
        if is_between(card.data.cnum, 1, 4) then return '' end
    end,
    ['OTP'] = function(card)
        if is_between(card.data.cnum, 1, 65) then return '' end
    end,
    ['OVNT'] = function(card)
        if
            includes({2005, 2006, 2009}, card.data.cnum) or
            is_between(card.data.cnum, 2012, 2015)
        then return card.data.collector_number end
    end,
    ['P15A'] = function(card)
        if card.data.cnum == 2 then return 'ST' end
    end,
    ['P30M'] = function(card)
        if card.data.collector_number == '1F★' then return 'Etched' end
    end,
    ['PAL00'] = function(card)
        if includes(card.data.types, 'Basic') then return '2000' end
    end,
    ['PAL01'] = function(card)
        if includes(card.data.types, 'Basic') then
            if card.data.cnum == 1 or card.data.cnum == 3 then return '2001a' end
            if card.data.cnum == 11 then return '2001b' end
            return '2001'
        end
    end,
    ['PAL02'] = function(card)
        if includes(card.data.types, 'Basic') then return '2001b' end
    end,
    ['PAL03'] = function(card)
        if includes(card.data.types, 'Basic') then return '2003' end
    end,
    ['PAL04'] = function(card)
        if includes(card.data.types, 'Basic') then return '2004' end
    end,
    ['PAL05'] = function(card)
        if includes(card.data.types, 'Basic') then return '2005' end
    end,
    ['PAL06'] = function(card)
        if includes(card.data.types, 'Basic') then return '2006' end
    end,
    ['PAL99'] = function(card)
        if includes(card.data.types, 'Basic') then return '1999' end
    end,
    ['PALP'] = function(card)
        if card.data.cnum <= 5 then return 'APAC Red' end
        if card.data.cnum <= 10 then return 'APAC Blue' end
        if card.data.cnum <= 15 then return 'APAC Clear' end
    end,
    ['PARL'] = function(card)
        if includes(card.data.types, 'Basic') then return '1996' end
    end,
    ['PDCI'] = function(card)
        if card.data.cnum == 69 then return '2' end
    end,
    ['PDGM'] = function(card)
        if card.data.collector_number == '157★' then return 'DGM' end
    end,
    ['PDOM'] = function(card)
        if card.data.collector_number == '182' then return '' end
    end,
    ['PELP'] = function(card)
        if card.data.cnum <= 5 then return 'Euro Blue' end
        if card.data.cnum <= 10 then return 'Euro Red' end
        if card.data.cnum <= 15 then return 'Euro Purple' end
    end,
    ['PGRN'] = function(card)
        if card.data.collector_number == '168' then return '' end
    end,
    ['PGRU'] = function() return 'Guru' end,
    ['PGPX'] = function(card)
        if card.data.collector_number:match('2018[a-f]') then return '2018' end
    end,
    ['PH18'] = function(card)
        if card.data.collector_number == '4' then return '1' end
        if card.data.collector_number == '4†' then return '2' end
    end,
    ['PIP'] = function(card)
        if
            is_between(card.data.cnum, 353, 355) or
            card.data.cnum == 357 or
            card.data.cnum == 361 or
            card.data.cnum == 1068
        then return '' end
        if is_between(card.data.cnum, 845, 854) then card.append_ver = true end
        if is_between(card.data.cnum, 855, 880) then return 'Showcase Surge' end
        if
            card.data.cnum == 884 or
            is_between(card.data.cnum, 886, 888)
        then return 'Alt Art Surge' end
        if is_between(card.data.cnum, 890, 1056) then return 'Ext Art Surge' end
    end,
    ['PJAS'] = function() return 'U' end,
    ['PJSE'] = function() return 'E' end,
    ['PKHM'] = function(card)
        if card.data.cnum == 1 then return '' end
    end,
    ['PKTK'] = function(card)
        if card.data.collector_number == '210p' then return 'P' end
        if card.data.collector_number == '210s' then return 'S' end
    end,
    ['PLG20'] = function() return '' end,
    ['PLS'] = function(card)
        if card.data.collector_number:match('★') then return 'Alt' end
    end,
    ['PLST'] = function(card)
        if
            card.name == 'Knight Exemplar' or
            card.name == 'Rout'
        then return card.data.collector_number:match('^([^-]*)') end
        if
            card.data.collector_number == 'MH2-412' or
            card.data.collector_number == 'MH2-402'
        then return 'Retro' end
        if
            card.data.collector_number == 'MH2-42' or   -- Floodhound, should be normal variant
            card.data.collector_number == 'MH2-204' or  -- Lonis, Cryptozoologist, should be normal variant
            card.data.collector_number == 'MH2-329'
        then return 'Sketch' end
        if card.data.collector_number == 'CHK-160' then return 'a' end
        if card.data.collector_number == 'JMP-50' then return '5' end
        if card.data.collector_number == 'PF19-1' then return 'Promo' end
        if card.data.collector_number == 'SOI-265' then return '434' end
    end,
    ['PLTR'] = function(card)
        if is_between(card.data.cnum, 400, 404) then return 'Promo' end
    end,
    ['PM19'] = function(card)
        if card.data.collector_number == '91' then return '' end
    end,
    ['PM20'] = function(card)
        if includes({69, 95, 139, 197, 206}, card.data.cnum) then return 'Promo Pack' end
        if card.data.collector_number == '131' then return 'Bundle' end
    end,
    ['PMPS'] = function(card)
        return (card.data.watermark:gsub('^%l', string.upper))
    end,
    ['PMPS06'] = function() return 'TSP' end,
    ['PMPS07'] = function() return 'LRW' end,
    ['PMPS08'] = function(card)
        if includes(card.data.types, 'Basic') then return 'ALA' end
    end,
    ['PMPS09'] = function() return 'ZEN' end,
    ['PMPS10'] = function() return 'SOM' end,
    ['PMPS11'] = function() return 'ISD' end,
    ['POR'] = function(card)
        -- Chinese alt-arts aren't in MA
        if card.data.collector_number:match('s') then
            card.append_ver = true
            return 'SKIP'
        end
        if card.data.collector_number:match('†') then return 'ST' end
        if card.data.collector_number:match('d') then return 'DG' end
    end,
    ['PPP1'] = function() return '' end,
    ['PPTK'] = function(card)
        if card.data.collector_number == '115a' then return 'April' end
        if card.data.collector_number == '115b' then return 'July' end
    end,
    ['PRIX'] = function(card)
        if card.data.collector_number == '130' then return '' end
    end,
    ['PRNA'] = function(card)
        if card.data.collector_number == '189' then return '' end
    end,
    ['PRW2'] = function(card) return card.data.collector_number end,
    ['PRWK'] = function(card) return card.data.collector_number end,
    ['PS14'] = function() return 'SDCC 14' end,
    ['PS15'] = function() return 'SDCC 15' end,
    ['PS16'] = function() return 'SDCC 16' end,
    ['PS17'] = function() return 'SDCC 17' end,
    ['PS18'] = function() return 'SDCC 18' end,
    ['PS19'] = function() return 'SDCC 19' end,
    ['PSDC'] = function() return 'SDCC 13' end,
    ['PSS2'] = function() return 'XLN' end,
    ['PSS3'] = function() return 'M19' end,
    ['PSUS'] = function(card)
        if is_between(card.data.cnum, 10, 17) then return 'J' end
    end,
    ['PTC'] = function(card)
        local name_lkup = {
            ['ml'] = 'Michael Loconto',
            ['mj'] = 'Mark Justice',
            ['pp'] = 'Preston Poulter',
            ['gb'] = 'George Baxter',
            ['ll'] = 'Leon Lindback',
            ['shr'] = 'Shawn Regnier',
            ['bl'] = 'Bertrand Lestree',
            ['et'] = 'Eric Tam',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb$') then
            ver = ver .. ' S'
        end
        local names = {
            'Circle of Protection: Green',
            'Circle of Protection: Red',
            'Forest',
            'Hymn to Tourach',
            'Island',
            'Memory Lapse',
            'Mountain',
            'Order of Leitbur',
            'Order of the Ebon Hand',
            'Plains',
            'Swamp',
        }
        if includes(names, card.name) then
            card.append_ver = true
        end
        local numbers = {'bl15sb', 'bl17sb', 'bl14sb', 'bl16sb', 'shr32asb', 'shr32bsb', 'ml15sb', 'ml17sb'}
        if includes(numbers, card.data.collector_number) then
            ver = ver .. '#'
        end
        return ver
    end,
    ['PTKDF'] = function() return 'Dragonfury' end,
    ['PUMA'] = function() return '' end,
    ['PW21'] = function(card)
        if card.name == 'Mind Stone' then return 'WPN 2021' end
        return ''
    end,
    ['PW24'] = function() return '' end,
    ['REX'] = function(card)
        if is_between(card.data.cnum, 1, 20) or card.data.cnum == 26 then return '' end
    end,
    ['RNA'] = function(card)
        if card.data.cnum == 273 then return '' end
    end,
    ['RVR'] = function(card)
        if is_between(card.data.cnum, 302, 415) then return 'Retro' end
        if card.data.cnum == 467 then return 'Promo' end
    end,
    ['SCH'] = function() return '' end,
    ['SLC'] = function() return '' end,
    ['SLD'] = function(card)
        if card.data.collector_number == 'VS' then return 'M11' end
        if card.data.collector_number == 'SCTLR' then return 'SCTLR' end
        if card.data.cnum == 728 then return '0728' end
        if card.data.cnum == 729 then return '0729' end
        if card.data.cnum == 1012 then return '1012' end
        if is_between(card.data.cnum, 159, 163) and card.data.collector_number:match('★') then
            return card.data.collector_number:gsub('★', ' Etched')
        end
        local ver = card.data.collector_number
        if #ver < 3 then
            ver = string.rep('0', 3 - #ver) .. ver
        end
        return ver
    end,
    ['SNC'] = function(card)
        if is_between(card.data.cnum, 450, 460) then return 'Box Topper ' .. card.data.collector_number end
    end,
    ['SOI'] = function(card)
        if card.data.collector_number == '265' then return '434' end
        if card.data.collector_number == '265†a' then return '546' end
        if card.data.collector_number == '265†b' then return '653' end
        if card.data.collector_number == '265†c' then return '711' end
        if card.data.collector_number == '265†d' then return '855' end
        if card.data.collector_number == '265†e' then return '922' end
    end,
    ['SPG'] = function(card)
        if card.data.cnum == 17 then
            if card.data.collector_number == '0017' then
                return ''
            else
                return card.data.collector_number:gsub('%d', '')
            end
        end
        if is_between(card.data.cnum, 1, 48) then return '' end
    end,
    ['STA'] = function(card)
        if is_between(card.data.cnum, 1, 63) then return '' end
        if card.data.cnum >= 64 then return 'Alt Art' end
    end,
    ['SLU'] = function() return '' end,
    ['THB'] = function(card)
        if is_between(card.data.cnum, 255, 257) then return 'Ext Art' end
        if card.data.cnum == 269 then return '' end
        if card.data.collector_number == '347★' then return 'Ext Art Foil' end
        if card.data.cnum == 352 then return 'Bundle' end
        if is_between(card.data.cnum, 353, 357) then return 'Promo Pack' end
    end,
    ['TSR'] = function(card)
        if card.data.cnum == 411 then return 'Buy-A-Box' end
    end,
    ['UGL'] = function(card)
        if card.data.cnum == 28 then return 'Left' end
        if card.data.cnum == 29 then return 'Right' end
    end,
    ['UND'] = function(card)
        if card.data.full_art == true then return 'Full' end
    end,
    ['UNF'] = function(card)
        if
            is_between(card.data.cnum, 200, 209) or
            is_between(card.data.cnum, 211, 234)
        then return string.sub(card.data.collector_number, -1, -1) end
        if
            is_between(card.data.cnum, 235, 239) or
            is_between(card.data.cnum, 277, 286)
        then return '' end
        if is_between(card.data.cnum, 240, 244) then return 'Orbital' end
        if is_between(card.data.cnum, 275, 276) then return 'Showcase' end
        if
            is_between(card.data.cnum, 287, 490) or
            is_between(card.data.cnum, 528, 537)
        then return 'Galaxy Foil' end
        if is_between(card.data.cnum, 491, 495) then return 'Orbital Foil' end
        if is_between(card.data.cnum, 496, 527) then return 'Showcase Galaxy' end
        if card.data.cnum == 538 then return 'Promo' end
    end,
    ['UST'] = function(card)
        if is_between(card.data.cnum, 167, 216) then return '' end
    end,
    ['VOW'] = function(card)
        if is_between(card.data.cnum, 278, 285) then return 'Ext Art' end
        if is_between(card.data.cnum, 317, 328) then return 'Eternal Night' end
    end,
    ['WAR'] = function(card)
        if card.data.cnum == 275 then return '' end
    end,
    ['WC00'] = function(card)
        local name_lkup = {
            ['jk'] = 'Janosch Kuhn',
            ['jf'] = 'John Finkel',
            ['nl'] = 'Nicolas Labarre',
            ['tvdl'] = 'Tom van de Logt',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC01'] = function(card)
        local name_lkup = {
            ['ab'] = 'Alex Borteh',
            ['ar'] = 'Antoine Ruel',
            ['jt'] = 'Jan Tomcani',
            ['tvdl'] = 'Tom van de Logt',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') or card.name == 'Counterspell' then
            card.append_ver = true
        end
        return ver
    end,
    ['WC02'] = function(card)
        local name_lkup = {
            ['bk'] = 'Brian Kibler',
            ['cr'] = 'Carlos Romao',
            ['rl'] = 'Raphael Levy',
            ['shh'] = 'Sim Han How',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC03'] = function(card)
        local name_lkup = {
            ['dz'] = 'Daniel Zink',
            ['dh'] = 'Dave Humpherys',
            ['pk'] = 'Peer Kroger',
            ['we'] = 'Wolfgang Eder',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC04'] = function(card)
        local name_lkup = {
            ['ap'] = 'Aeo Paquette',
            ['gn'] = 'Gabriel Nassif',
            ['jn'] = 'Julien Nuijten',
            ['mb'] = 'Manuel Bevand',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC97'] = function(card)
        local name_lkup = {
            ['pm'] = 'Paul McCabe',
            ['jk'] = 'Janosch Kuhn',
            ['js'] = 'Jakub Slemr',
            ['sg'] = 'Svend Geertsen',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb$') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC98'] = function(card)
        local name_lkup = {
            ['br'] = 'Ben Rubin',
            ['bh'] = 'Brian Hacker',
            ['bs'] = 'Brian Selden',
            ['rb'] = 'Randy Buehler',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WC99'] = function(card)
        local name_lkup = {
            ['js'] = 'Jakub Slemr',
            ['kb'] = 'Kai Budde',
            ['mlp'] = 'Mark Le Pine',
            ['ml'] = 'Matt Linde',
        }
        local ver = name_lkup[card.data.collector_number:match('^([a-z]*)')]
        if card.data.collector_number:match('sb') then
            ver = ver .. ' S'
        end
        if includes(card.data.types, 'Basic') then
            card.append_ver = true
        end
        return ver
    end,
    ['WHO'] = function(card)
        if card.data.cnum == 565 then return 'Promo' end
        if card.data.cnum == 789 then return '1 Surge' end
        if card.data.cnum == 790 then return '2 Surge' end
        if card.data.cnum == 791 then return '3 Surge' end
        if is_between(card.data.cnum, 854, 857) then card.append_ver = true end
        if is_between(card.data.cnum, 923, 1125) then return 'Surge Ext Art' end
        if is_between(card.data.cnum, 1126, 1155) then return 'Surge Showcase' end
        if is_between(card.data.cnum, 1156, 1165) then card.append_ver = true end
    end,
    ['WOC'] = function(card)
        if is_between(card.data.cnum, 57, 58) then return 'Etched' end
    end,
    ['WOT'] = function(card)
        if card.data.cnum <= 63 then return '' end
    end,
    ['ZNR'] = function(card)
        if card.data.cnum == 385 then return 'Buy-a-Box' end
        if card.data.cnum == 386 then return 'Bundle' end
        if is_between(card.data.cnum, 387, 391) then return 'Promo Pack' end
    end,
}

--[[ Utility function to check if a value exists in a table; returns boolean
    table   the table to check
    value   the value to check for
--]]
function includes(table, value)
    if type(table) ~= 'table' then return false end
    for _, table_entry in ipairs(table) do
        if table_entry == value then return true end
    end
    return false
end

--[[ Utility function to check if a number falls within a range, returns boolean
    number  the number to check
    min     the lowest matching number (incluive)
    max     the highest matching number (inclusive)
--]]
function is_between(number, min, max)
    return number >= min and number <= max
end

--[[ Function to log card details in MA's log; by default, it prints the following:
        name, collector number, old version if reparsed, version, nonfoil price, foil price
    If SHOW_MORE logging option is set, this will then print the following:
        set code/set id, language/lang_id, object type
    If DUMP_JSON logging option is set, this will then dump the card's raw data

    card    a card record from parse_card
    msg     a message to print before the card details
--]]
function log_card(card, msg)
    local line_1 = {}
    if msg then
        table.insert(line_1, msg)
    end
    table.insert(line_1, card.name .. ' #' .. card.data.collector_number .. ' [')
    if card.old_ver then
        table.insert(line_1, card.old_ver .. ' -> ')
    end
    table.insert(line_1, card.ver .. '] (' .. card.price_reg .. ', ' .. card.price_foil .. ')')
    ma.Log(table.concat(line_1))
    if SHOW_MORE then
        local lang_code = ''
        for key, val in pairs(lang_lkup) do
            if card.lang_id == val then
                lang_code = key
            end
        end
        local line_2 = {}
        table.insert(line_2, '    set: ' .. card.data.set .. '/' .. card.set_id)
        table.insert(line_2, ', language: ' .. lang_code .. '/' .. card.lang_id)
        table.insert(line_2, ', obj_type: ' .. card.obj_type)
        ma.Log(table.concat(line_2))
    end
    if DUMP_JSON then
        ma.Log(json.encode(card.data))
    end
end

--[[ Function to set a card's prices in MA; returns true on success, false on failure
    card        a card record from parse_card
    print_log   (bool) whether or not to print to MA's log
--]]
function set_card_price(card, print_log)
    --send the card to MA
    local result = ma.SetPrice(card.set_id, card.lang_id, card.name, card.ver, card.price_reg, card.price_foil, card.obj_type)
    -- if no matches found, cache this card to try later
    if result == 0 then
        if print_log and LOG_FAILURE then
            log_card(card, 'F: ')
        end
        return false
    else
        if print_log and LOG_SUCCESS then
            log_card(card, 'S: ')
        end
        return true
    end
end

--[[ Function to check if a card object has an etched price set
    May modify the card record passed in by mapping etched price to foil price
    Returns a card record if the input record has both etched and foil prices
    Returns nil if the input record has no etched version
    
    card    a card record from parse_card
--]]
function check_for_etched(card)
    if includes(card.data.finishes, 'etched') then
        if not includes(card.data.finishes, 'foil') then
            -- if there's no foil version, map etched price to foil price
            card.price_foil = card.data.prices.usd_etched or 0
        else
            -- if both exist, MA should have a separate entry for the etched version
            local etched_card = {}
            for key, val in pairs(card) do etched_card[key] = val end
            if card.ver == '' then
                etched_card.ver = 'Etched'
            else
                etched_card.ver = card.ver .. ' Etched'
            end
            etched_card.price_reg = 0
            etched_card.price_foil = card.data.prices.usd_etched or 0
            return etched_card
        end
    end
end

--[[ Function to parse a card; returns the card record if setting the price in MA failed
    card_data   decoded JSON data for a card from Scryfall
    set         set record from available_sets
    lang_id     language id from MA
--]]
function parse_card(card_data, set, lang_id)
    -- in promo sets, filter out cards that don't match the criteria
    if set.is_promo_set ~= nil then
        local card_will_be_skipped = true
        -- first, allow card if it's tagged as a promo by scryfall
        if card_data.promo then
            card_will_be_skipped = false
        end
        if promo_sets[set.id] then
            -- second, disallow card if it doesn't match the promo_set's type
            if not includes(card_data.promo_types, promo_sets[set.id]['type']) then
                card_will_be_skipped = true
            end
            -- finally, allow card if it's on the set's whitelist
            if
                card_will_be_skipped and
                promo_sets[set.id]['whitelist'] and
                promo_sets[set.id]['whitelist'][set.code] and
                promo_sets[set.id]['whitelist'][set.code][card_data.collector_number]
            then
                card_will_be_skipped = false
            end
        end
        if card_will_be_skipped then return end
    end
    -- filter out non-paper cards
    if not includes(card_data.games, 'paper') then return end
    -- set test prices
    if TEST_PRICES then
        if includes(card_data.finishes, 'nonfoil') then card_data.prices.usd = '1.00' end
        if includes(card_data.finishes, 'foil') then card_data.prices.usd_foil = '1.00' end
        if includes(card_data.finishes, 'etched') then card_data.prices.usd_etched = '1.00' end
    end

    -- set up the card record
    local card = {
        name       = card_data.name,
        ver        = '',
        price_reg  = card_data.prices.usd or 0,
        price_foil = card_data.prices.usd_foil or 0,
        set_id     = set.id,
        lang_id    = lang_lkup[card_data.lang] or lang_id,
        obj_type   = CARD_OBJECT,
        data       = card_data
    }

    --[[ process card name ]]
    -- change multipart card separator into MA's format
    card.name = card.name:gsub(' // ','|')
    -- check the list of specific name replacements
    if name_replace[card.name] ~= nil then card.name = name_replace[card.name] end
    -- handle Unstable variants
    if set.id == 857 then
        local variant = card.data.collector_number:gsub('%d','')
        if
            card.data.rarity ~= 'common' and
            variant ~= ''
        then
            card.name = card.name .. ' (' .. variant .. ')'
        end
    end

    --[[ process object type ]]
    --TODO: tokens & inserts
    if
        card.data.set_type == 'memorabilia' or
        card.data.oversized or
        includes(card.data.promo_types, 'thick')
    then
        card.obj_type = REPLICA_OBJECT
    end
    if
        includes(card.data.types, 'Vanguard') or
        includes(card.data.types, 'Plane') or
        includes(card.data.types, 'Phenomenon') or
        includes(card.data.types, 'Scheme') or
        includes(card.data.types, 'Conspiracy') or
        includes({'THP1', 'THP2', 'THP3', 'TFTH', 'TBTH', 'TDAG'}, set.code)
    then
        card.obj_type = NONTRAD_OBJECT
    end

    --[[ process card version ]]
    -- see if there's a match in version_lookup
    if version_lookup[set.code] then
        local version = version_lookup[set.code](card)
        if version ~= nil then
            card.ver = version
            -- if so, the usual version checks can be skipped
            goto skip_version
        end
    end

    -- borderless cards
    if card.data.border_color == 'borderless' then
        card.ver = 'Alt Art'
    end
    -- frame_effects
    if includes(card.data.frame_effects, 'extendedart') then
        card.ver = 'Ext Art'
    end
    if includes(card.data.frame_effects, 'showcase') then
        card.ver = 'Showcase'
    end
    if includes(card.data.frame_effects, 'shatteredglass') then
        card.ver = 'Shattered'
    end
    -- promo_types
    if includes(card.data.promo_types, 'portrait') then
        card.ver = 'Profile'
    end
    if includes(card.data.promo_types, 'ripplefoil') then
        if not includes(card.data.finishes, 'nonfoil') then
            card.ver = 'Ripple'
        end
    end
    if includes(card.data.promo_types, 'textured') then
        card.ver = 'Textured'
    end
    if includes(card.data.promo_types, 'gilded') then
        card.ver = 'Gilded'
    end
    if includes(card.data.promo_types, 'embossed') then
        card.ver = 'Embossed'
    end
    if includes(card.data.promo_types, 'stepandcompleat') then
        card.ver = 'Compleat'
    end
    if includes(card.data.promo_types, 'raisedfoil') then
        card.ver = 'Raised'
    end
    if includes(card.data.promo_types, 'oilslick') then
        card.ver = 'Oil'
    end
    if includes(card.data.promo_types, 'halofoil') then
        card.ver = 'Halo'
    end
    if includes(card.data.promo_types, 'magnified') then
        card.ver = 'Magnified'
    end
    if includes(card.data.promo_types, 'dossier') then
        card.ver = 'Dossier'
    end
    if includes(card.data.promo_types, 'invisibleink') then
        card.ver = 'Invisible Ink'
    end
    if includes(card.data.promo_types, 'confettifoil') then
        card.ver = 'Confetti'
    end

    -- bundle promos
    if includes(card.data.promo_types, 'bundle') then
        if not card.data.type_line:match('Basic') then
            card.ver = 'Promo'
        end
    end
    -- buy-a-box promos
    if includes(card.data.promo_types, 'buyabox') then
        card.ver = 'Promo'
        -- special case for the buy-a-box promo set
        if set.id == 50 then
            card.ver = ''
        end
    end
    -- intro pack promos
    if includes(card.data.promo_types, 'intropack') then
        card.ver = set.code:gsub('^P','')
    end
    -- play promos
    if includes(card.data.promo_types, 'playpromo') then
        card.ver = 'Promo'
    end
    -- prerelease promos
    if includes(card.data.promo_types, 'prerelease') then
        if includes(card.data.promo_types, 'datestamped') then
            card.ver = 'S'
        else
            card.ver = 'Promo'
        end
        -- special case for the prerelease promo set
        if set.id == 22 then
            card.ver = ''
            -- eventually these should be moved to their own promo sets
            if includes({'POGW', 'PSOI', 'PEMN', 'PKLD', 'PHOU'}, set.code) then
                card.ver = set.code:gsub('^P', '')
            end
        end
    end
    -- promo pack promos
    if includes(card.data.promo_types, 'promopack') then
        if includes(card.data.promo_types, 'stamped') then
            card.ver = 'P'
        else
            card.ver = 'Promo'
        end
    end
    -- store championship promos
    if includes(card.data.promo_types, 'storechampionship') then
        card.ver = 'Promo'
    end

    -- double rainbow cards
    if includes(card.data.promo_types, 'doublerainbow') then
        card.ver = 'Serialized'
    end
    -- neon ink cards
    if includes(card.data.promo_types, 'neonink') then
        card.ver = 'Neon ' .. string.sub(card.data.collector_number, -1, -1)
    end
    -- surge foils
    if includes(card.data.promo_types, 'surgefoil') then
        card.ver = 'Surge'
    end
    -- etched foils
    if
        not includes(card.data.finishes, 'nonfoil') and
        not includes(card.data.finishes, 'foil') and
        includes(card.data.finishes, 'etched')
    then
        card.ver = 'Etched'
    end
    -- display commanders
    if includes(card.data.promo_types, 'thick') and includes(card.data.types, 'Legendary') then
        card.ver = 'Display'
    end
    -- end of version checks
    ::skip_version::

    --[[ apply card-specific overrides ]]
    if card_hacks[set.code] and card_hacks[set.code][card.data.collector_number] then
        for key, val in pairs(card_hacks[set.code][card.data.collector_number]) do
            card[key] = val
        end
    end

    -- check for an etched price
    local etched_card = check_for_etched(card)
    -- attempt to set the price in MA
    local result = set_card_price(card, LOG_INITIAL)
    -- if there's an etched version, send that to MA as a separate entry
    if type(etched_card) == 'table' then
        set_card_price(etched_card, LOG_INITIAL)
    end
    -- if price couldn't be set, return this card to try later
    if not result then return card end
end

--[[ Function that takes a table of card records, generates sequential version numbers for them,
    and attempts to set the price again
    cards_to_reparse    a table of card records from parse_card
    set                 set record from available_sets
--]]
function reparse_failed_cards(cards_to_reparse, set)
    local group_names = {}
    for _, card in ipairs(cards_to_reparse) do
        local group_name = ''
        if card.append_ver then
            group_name = card.name .. '%' .. card.ver
        else
            group_name = card.name
        end
        if not includes(group_names, group_name) then
            table.insert(group_names, group_name)
        end
    end
    -- generate sequential version numbers based on collector number order
    for _, group_name in ipairs(group_names) do
        local group_cards = {}
        local group_cnums = {}
        -- save matching cards and their cnums to tables
        for _, card in ipairs(cards_to_reparse) do
            local match = false
            if card.append_ver then
                match = card.name .. '%' .. card.ver == group_name
            else
                match = card.name == group_name
            end
            if match then 
                table.insert(group_cards, card)
                table.insert(group_cnums, card.data.collector_number)
            end
        end
        -- assign each cnum a version
        local order = {}
        local last_ver = 0
        for _, cnum in ipairs(group_cnums) do
            if order[cnum:gsub('★', '')] then
                -- foils with a suffixed cnum (7e, 8e, 9e) get the same ver as the nonfoil
                order[cnum] = order[cnum:gsub('★', '')]
            else
                -- assign card the next sequenial version
                last_ver = last_ver + 1
                order[cnum] = last_ver
            end
        end
        -- loop through the group, add the version number, then attempt to set prices again
        for _, card in ipairs(group_cards) do
            local new_ver = order[card.data.collector_number]
            -- zero padding: last_ver holds highest version number assigned to this group
            -- use that value to determine if padding is needed 
            if last_ver > 9 then
                new_ver = string.format('%02d', new_ver)
            end
            -- store the old version for logging purposes
            card.old_ver = card.ver
            -- update card with the new version
            if card.append_ver then
                if card.ver:match('#') then
                    card.ver = card.ver:gsub('#', new_ver)
                else
                    card.ver = card.ver .. ' ' .. new_ver
                end
            else
                card.ver = new_ver
            end
            -- check for an etched price
            local etched_card = check_for_etched(card)
            -- attempt to set the price again
            set_card_price(card, LOG_REPARSE)
            -- if there's an etched version, send that to MA as another entry
            if etched_card ~= nil then 
                set_card_price(etched_card, LOG_REPARSE)
            end
        end
    end
    -- reset the reparse list
    cards_to_reparse = {}
end

--[[ Function to read and parse one JSON file from Scryfall
    set         set record from available_sets
    lang_id     language id
--]]
function parse_set(set, lang_id)
    -- make sure the file for this set want exists
    local file_name = 'Prices\\Scryfall\\' .. set.code .. '_.txt'
    local json_data = ma.GetFile(file_name)
    if json_data == nil then
        ma.Log('File ' .. file_name .. ' not found.')
        return {}
    end
    local set_data = json.decode(json_data)
    -- sort set by cnum
    local max_cnum_length = 0
    local max_suffix_length = 0
    local pattern = '%d*([^%d]*)'   -- pattern to match characters that follow digits
    for _, card in ipairs(set_data) do
        -- store an ascii version of the cnum
        card.sortable_cnum = card.collector_number:gsub('★', '~')
        -- also store a numeric version of the cnum (used for setting versions)
        card.cnum = card.collector_number:gsub('[^%d]', '')
        card.cnum = tonumber(card.cnum)
        -- get the maximum length of the cnum and of any suffixes following the cnum's digits
        local suffix = card.sortable_cnum:match(pattern)
        if #suffix > max_suffix_length then
            max_suffix_length = #suffix
        end
        if #card.sortable_cnum > max_cnum_length then
            max_cnum_length = #card.sortable_cnum
        end
        -- split and store type line as a table
        local types = {}
        if card.type_line then
            for word in card.type_line:gmatch('[^%s]+') do
                table.insert(types, word)
            end
        end
        card.types = types
    end
    -- pad the cnums with spaces so they are text sortable
    for _, card in ipairs(set_data) do
        local target_cnum_length = max_cnum_length + max_suffix_length
        local suffix = card.sortable_cnum:match(pattern)
        if max_suffix_length > #suffix then
            card.sortable_cnum = card.sortable_cnum .. string.rep(' ', max_suffix_length - #suffix)
        end
        if target_cnum_length > #card.sortable_cnum then
            card.sortable_cnum = string.rep(' ', target_cnum_length - #card.sortable_cnum) .. card.sortable_cnum
        end
    end
    table.sort(set_data, function(a, b)
        return a.sortable_cnum < b.sortable_cnum
    end)
    local cards_to_reparse = {}
    -- loop through the cards in the set
    for _, card in ipairs(set_data) do
        result = parse_card(card, set, lang_id)
        -- cache failed cards to retry later
        if type(result) == 'table' then
            table.insert(cards_to_reparse, result)
        end
    end
    -- retry the failed matches with sequential version numbers
    reparse_failed_cards(cards_to_reparse, set)
end

--[[ Function to handle promo sets spread across many JSON files
    set         set record from available_sets
    lang_id     language id
--]]
function parse_promo_set(set, lang_id)
    -- clone the list of promo set codes, since we may need to modify it
    local promo_set_codes = {}
    for _, set_code in ipairs(promo_sets[set.id]['sets']) do
        table.insert(promo_set_codes, set_code)
    end
    -- if this set needs more set codes, add them to the cloned list
    if promo_sets[set.id]['more_sets'] then
        for _, set_code in ipairs(promo_sets[set.id]['more_sets']) do
            table.insert(promo_set_codes, set_code)
        end
    end
    -- parse each of the sets on the cloned list
    for _, set_code in ipairs(promo_set_codes) do
        parse_set({id = set.id, code = set_code, is_promo_set = true}, lang_id)
    end    
end

-- Main startup function, called by MA
function ImportPrice(import_foil, import_langs, import_sets)
    -- calculate total number of set files to parse for the progress bar
    local total_set_count = 0
    for _, set in ipairs(available_sets) do
        if import_sets[set.id] ~= nil then
            if import_langs[ENG_ID] ~= nil then
                total_set_count = total_set_count + 1
            end
        end
    end
    -- main import cycle
    local complete_set_count = 0
    for _, set in ipairs(available_sets) do
        -- bail on non-matching sets and languages
        if import_sets[set.id] == nil or import_langs[ENG_ID] == nil then goto continue end
        -- update the progress bar
        ma.SetProgress('Updating ' .. import_sets[set.id], 100 * complete_set_count / total_set_count)
        if set.code == 'PROMOS' then
            parse_promo_set(set, ENG_ID)
        else
            parse_set(set, ENG_ID)
        end
        complete_set_count = complete_set_count + 1
        ::continue::
    end
end
