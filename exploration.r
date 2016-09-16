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

spawn_ids = pokemon[,.N,spawnpoint_id][N>20, spawnpoint_id]
setkey(pokemon, spawnpoint_id)
pokemon_spawns = pokemon[spawn_ids]
pokemon_spawns[,spawn_id:=.GRP, spawnpoint_id]
vals = pokemon_spawns[, .N, .(spawn_id, pokemon_id)]

#pokemon_spawns[,.N,pokemon_id][order(pokemon_id)] # sanity checking that we have a diversity of mons across this subset of spawns


library(Matrix)
m = vals[,sparseMatrix(i=spawn_id, j=pokemon_id, x=N)]
m_dense = as.matrix(m)

library(proxy)
d = dist(m_dense, method='cosine')
#image(as.matrix(d))
clust = hclust(d)

#plot(clust) # not very informative
image(as.matrix(d)[clust$order,clust$order])
# looks liek about 12 main clusters. Call it 15-20 to be safe.

library(arules)

# focus on dratini spawns
rules = apriori(m_dense[m_dense[,147]==1,])
inspect(rules[1:500]) # looks like dratini like water. Co-occur with golduck and magikarp.

# Use LDA to identify latent biomes as soft clusters
library(topicmodels)
library(tm)

pokemon_info = fread(paste0('data/raw/','pokemon_info.csv'))

# Should probably move this further up. It's necessary to get information on topics.
# LDA apparently doesn't tolerate numeric (or rather, unspecified) terms.
colnames(m_dense) = pokemon_info[1:149,english_name]

dt_mat = as.DocumentTermMatrix(m_dense, weighting=weightTf)
lda_mod = LDA(dt_mat, 15)

terms(lda_mod,10) # All of my topics are null :(

