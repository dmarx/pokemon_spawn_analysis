#setwd('/media/Storage/Projects/pokemon_spawn_analysis/')
#setwd('C:/Users/davidmarx/Documents/Projects/Toy Projects/pokemon_spawn_analysis')
library(data.table)

pokemon = fread('pokemon.csv')
scannedlocation = fread('scannedlocation.csv')
pokestop = fread('pokestop.csv')
gym = fread('gym.csv')

pokemon_columns = c('encounter_id','spawnpoint_id','pokemon_id','latitude','longitude','disappear_time')
setnames(pokemon, names(pokemon), pokemon_columns)

pokemon[,.N] # 904016 spawns
pokemon[,1,spawnpoint_id][,.N] # 338334 spawn points
pokemon[,.N,spawnpoint_id][N>20,.N] # just 4524 spawnpoints with more than 20 associated spawns
