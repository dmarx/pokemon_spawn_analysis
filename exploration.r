#setwd('/media/Storage/Projects/pokemon_spawn_analysis/')
library(data.table)

pokemon = fread('pokemon.csv')
scannedlocation = fread('scannedlocation.csv')
pokestop = fread('pokestop.csv')
gym = fread('gym.csv')

pokemon_columns = c('encounter_id','spawnpoint_id','pokemon_id','latitude','longitude','disappear_time')
setnames(pokemon, names(pokemon), pokemon_columns[1:5])

pokemon[,.N] # 598427 spawns
pokemon[,1,spawnpoint_id][,.N] # 251604 spawn points
pokemon[,.N,spawnpoint_id][N>20,.N] # just 2434 spawnpoints with more than 20 associated spawns

spawn_ids = pokemon[,.N,spawnpoint_id][N>20, spawnpoint_id]
setkey(pokemon, spawnpoint_id)
pokemon_spawns = pokemon[spawn_ids]
pokemon_spawns[,spawn_id:=.GRP, spawnpoint_id]
vals = pokemon_spawns[, .N, .(spawn_id, pokemon_id)]

library(Matrix)
m = vals[,sparseMatrix(i=spawn_id, j=pokemon_id, x=N)]
m_dense = as.matrix(m)

library(proxy)
d = dist(m_dense, method='cosine')
image(as.matrix(d))
clust = hclust(d)

plot(clust) # not very informative
image(as.matrix(d)[clust$order,clust$order])


library(arules)

rules = apriori(m_dense)
inspect(rules[1:500])

