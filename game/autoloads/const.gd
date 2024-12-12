extends Node

const STAGE_ROOT := "res://game/stages/"
const STAGE_MAIN := "main_menu_stage.tscn"
const STAGE_GAME := "game_stage.tscn"

const SCREEN_ROOT := "res://game/screens/"
const SCREEN_HISTORY := "history.tscn"
const SCREEN_OPTIONS := "options_screen.tscn"
const SCREEN_CREDITS := "credits.tscn"
const SCREEN_CONTENT_WARNING := "cw.tscn"

const BACKGROUND_ROOT := "res://game/backgrounds/"
const BACKGROUND_AUTUMN := "autumn.png"
const BACKGROUND_BENCH := "bench/bench_day.tscn"
const BACKGROUND_BENCH_NIGHT := "bench/bench_night.tscn"
const BACKGROUND_BENCH_PATHWAY := "bench_pathway.png"
const BACKGROUND_BENCH_PATHWAY_NIGHT := "bench_pathway_night.png"
const BACKGROUND_BUS_RIDE := "bus_ride.png"
const BACKGROUND_CITY := "city.png"
const BACKGROUND_CITY_WALLS := "city_walls.png"
const BACKGROUND_CLERICANT_INTERROGATION_CHAMBER := "clericant_chambers/clericant_interrogation_chamber.tscn"
const BACKGROUND_CLERICANT_TORTURE_CHAMBER := "clericant_chambers/clericant_torture_chamber.tscn" # ph
const BACKGROUND_CLERIFUGIUM := "clerifugium.png"
const BACKGROUND_FIELD := "field/Field.tscn"
const BACKGROUND_GODS := "gods.png"
const BACKGROUND_HOME_REGULAR := "home_regular.png"
const BACKGROUND_HOME_REGULAR_NIGHT := "home_regular_night.png"
const BACKGROUND_HOME_BEDROOM := "home_bedroom.png"
const BACKGROUND_HOME_BEDROOM_NIGHT := "home_bedroom_night.png"
const BACKGROUND_HOME_KITCHEN := "home_kitchen.png"
const BACKGROUND_HUNTING_GROUNDS := "hunting_grounds.png"
const BACKGROUND_NEXUS := "nexus.png"
const BACKGROUND_RIVERBANK := "riverbank.png"
const BACKGROUND_SPECTRA_APARTMENT := "spectra_apartment.png"
const BACKGROUND_SUBURB := "city.png"
const BACKGROUND_TRAIN := "train/Train.tscn" # ph
const BACKGROUND_TRAIN_YARD := "train_yard.png"
const BACKGROUND_WARZONE := "warzone.png"

# attribution license:
# https://rozkol.bandcamp.com/track/iii
# https://rozkol.bandcamp.com/album/machine-masochist
const MUSIC_ROOT := "res://game/sounds/music/"
const MUSIC_MAIN_MENU := "Opal Vessel - Worthless - Alone - 01 Suffocate.ogg"
const MUSIC_BLOODLETTING := "CØL - Post-Traumatic - 02 No Eyes, No Tongue.ogg"
const MUSIC_COL8822 := "CØL - What Makes Me Feel Alive - 02 8822.ogg"
const MUSIC_CONSUME_THE_BODY := "Is It Just Me inst.ogg"
const MUSIC_DATE := "Beat Mekanik - Inhale.mp3" # https://freemusicarchive.org/music/beat-mekanik/single/inhale/
const MUSIC_DONT_DIE_ON_ME := "CØL - Incessant Depression -KsureN + CØL Split- - 01 Don't Die on Me.ogg"
const MUSIC_GENTLE := "CØL - Wellness Checks - 06 Moonlights -Interlude-.ogg"
const MUSIC_GODS := "Princess Commodore 64 - The Death Of A Lifestyle - 04 VHS nation.ogg" # https://lostangles.bandcamp.com/album/the-death-of-a-lifestyle
const MUSIC_GRIEF := "Lonesummer - There Are Few Tomorrows for Feeding Our Worries - 12 Despair Will Hold a Place in My Heart, a Bigger One than You Do.ogg" # PH
const MUSIC_HOPE := "Hope.ogg"
const MUSIC_INTERROGATION := "ROZKOL - VI (Songs from Mid-World) - 16 Go then, there are other worlds than these.ogg"
const MUSIC_INTRO := "759304__kevp888__240819_2825_fr_church_organ_rehearsal.ogg" # kevp888 - 240819_2825_FR_Church_organ_rehearsal - https://freesound.org/people/kevp888/sounds/759304/
const MUSIC_LEARNING := "CØL - Wellness Checks - 02 Reckless.ogg"
const MUSIC_OMINOUS := "Princess Commodore 64 - The Death Of A Lifestyle - 06 special containment.ogg" # https://lostangles.bandcamp.com/track/special-containment
const MUSIC_ONE_DYING := "CØL - What Makes Me Feel Alive II - 10 Focus On Me.ogg"
const MUSIC_PANIC := "Lost Light inst.ogg"
const MUSIC_PLACE_CLERICANT_SHRINE := "ROZKOL - Machine Masochist - 01 Machine Masochist.ogg"
const MUSIC_PRISON := "Curls-inst.ogg"
const MUSIC_REUNITED := "Feeling_Blue.mp3" # https://dova-s.jp/EN/bgm/play15228.html
const MUSIC_SEDATION := "CØL - Picking Flowers - 11 Unveiled.ogg"
const MUSIC_SEX_ANHEDONIA := "Fio_PlaceWithTheGuitars-full.mp3"
const MUSIC_SEX_ANHEDONIA_JUSTPADS := "Fio_PlaceWithTheGuitars-justPads.mp3"
const MUSIC_SEX_ANHEDONIA_NODRUMS := "Fio_PlaceWithTheGuitars-noDrums.mp3"
const MUSIC_SEX_ONE := "My Sun and Moon_Full.mp3"
const MUSIC_SEX_ONE_NODRUMS := "My Sun and Moon_noDrums.mp3"
const MUSIC_SEX_ONE_NODRUMSNOBASS := "My Sun and Moon_noDrumsnoBass.mp3"
const MUSIC_SPECTRA := "Marco Trovatello - Violin Spider.mp3" #https://freemusicarchive.org/music/Marco_Trovatello/Not_At_All/06_-_Violin_Spider/
const MUSIC_SPECTRA_ONE := "CØL - Picking Flowers - 01 Alcohol.ogg"
const MUSIC_SUSPENSION_SEX := "Paradise_Found.mp3" # PH
const MUSIC_TORTURE := "ROZKOL - Machine Masochist - 06 Oubliette.ogg"
const MUSIC_TRAIN := "Paradise_Found.mp3" # PH
const MUSIC_WALK_TO_DEATH := "Lonesummer - There Are Few Tomorrows for Feeding Our Worries - 08 There Are Few Tomorrows for Feeding Our Worries.ogg"
const MUSIC_WASTELAND := "Jangwa - Dark Hearts.mp3"#https://freemusicarchive.org/music/Dilating_Times/cycles-trax-vol-v-drones/dark-hearts/
const MUSIC_WORK_AFTER_LOSS := "CØL - Post-Traumatic - 01 C Stands for Complex.ogg"
const MUSIC_WORKING := "CØL - Reset - Respond - 02 They'd Love Me More If I Were Dead.ogg"
const MUSIC_WORKING2 := "CØL - Unmedicated III- Close to Suicide - 01 Shower Drain.ogg"

const SFX_ROOT := "res://game/sounds/sfx/"
const SFX_CLERICANT_PHONE := "340922__passairmangrace__phonehomerings_quiet_stereo_bip.ogg" # PhoneHomeRings_Quiet_stereo_bip.wav by passAirmangrace -- https://freesound.org/s/340922/ -- License: Attribution 3.0
const SFX_CLINK := "592005__ueffects__climbing-express-gear.ogg"
const SFX_EXPLOSION := "explosion.ogg"
const SFX_GUNSHOT := "417345__inspectorj__gunshot-distant-a.ogg"
const SFX_KICK := "663159__voxlab__nazi-wehrmacht-march-stomp-pulse-2-rr13.wav"
const SFX_SQUELCH := "500912__bertsz__squish-impact.ogg"
const SFX_VOMIT := "vomit.ogg"
