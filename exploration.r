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
lda_mod = LDA(dt_mat, 20)
terms(lda_mod,10) # Again, looks like dratini clusters with water pokemon

-log(posterior(lda_mod)$terms)

# Clustering in topic space
topic_d = dist(t(posterior(lda_mod)$terms), method="cosine")
topic_clust = hclust(topic_d)
image(as.matrix(topic_d)[topic_clust$order,topic_clust$order]
      #,xlab=pokemon_info[topic_clust$order, english_name]
      )

# Try to get some labels in there... needs work
cbind(
  seq(0,1, length.out=149),
  pokemon_info[topic_clust$order, .(pokedex_number, english_name)]
)[1:100]

axis(1, at=seq(0,1, length.out=149), labels=pokemon_info[topic_clust$order, english_name])
axis(2, at=seq(0,1, length.out=149), labels=pokemon_info[topic_clust$order, english_name])

par(cex=0.5)
#plot(as.dendrogram(topic_clust), horiz=TRUE)
plot(topic_clust)

# Let's visualize this as a graph
hist(c(1-as.matrix(topic_d)))
adj = 1-as.matrix(topic_d)
thresh = .75
adj[adj<thresh] = 0

library(igraph)

g = graph_from_adjacency_matrix(adj, mode="undirected", weighted=TRUE, diag=FALSE)

lyt = layout_with_graphopt(g,charge=0.03)
#lyt <- norm_coords(lyt, ymin=-.5, ymax=.5, xmin=-.5, xmax=.5)
plot(g, layout=lyt, rescale=TRUE)

# dump edgelist to plot with gephi
el = as.data.table(get.edgelist(g))
setnames(el, names(el), c('Source','Target'))

el[,Weight:=E(g)$weight]

write.csv(el, 'data/pokemon_edgelist_from_topics.csv')
