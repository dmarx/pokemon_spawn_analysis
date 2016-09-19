#setwd('/media/Storage/Projects/pokemon_spawn_analysis/')
#setwd('C:/Users/davidmarx/Documents/Projects/Toy Projects/pokemon_spawn_analysis')
library(data.table)

pokemon_info = fread(paste0('data/raw/','pokemon_info.csv'))

#source('code/read/read_mysql_csv_dumps.r')
source('code/read/read_canberra_data.r')

spawn_ids = pokemon[,.N,spawnpoint_id][N>100, spawnpoint_id]
setkey(pokemon, spawnpoint_id)
pokemon_spawns = pokemon[spawn_ids]
pokemon_spawns[,spawn_id:=.GRP, spawnpoint_id]
vals = pokemon_spawns[, .N, .(spawn_id, pokemon_id)]

#pokemon_spawns[,.N,pokemon_id][order(pokemon_id)] # sanity checking that we have a diversity of mons across this subset of spawns


library(Matrix)
m = vals[,sparseMatrix(i=spawn_id, j=pokemon_id, x=N)]
colnames(m) = pokemon_info[1:149,english_name]
m_dense = as.matrix(m)


#######################################
### Cluster spawns in pokemon space ###
#######################################

library(proxy)
system.time(d <- dist(m_dense, method='cosine'))
#image(as.matrix(d))
clust = hclust(d)

#plot(clust) # not very informative
image(as.matrix(d)[clust$order,clust$order])
# looks liek about 12 main clusters. Call it 15-20 to be safe.


########################################################
### Find correlations between pokemon w/ assoc rules ###
########################################################

library(arules)
m_binary = copy(m_dense)
m_binary[m_binary>0] = 1
names(m_binary) = NULL
system.time(rules <- apriori(as.matrix(m_binary)))
# focus on dratini spawns
#system.time(rules <- apriori(m_dense[m_dense[,147]==1,]))
inspect(rules[1:500]) # looks like dratini like water. Co-occur with golduck and magikarp.

##########################################################
### Use LDA to identify latent biomes as soft clusters ###
##########################################################
#install.packages('slam') # My old OS can't handle new R :(

#require(devtools)
#install_version("slam", 
#                version = "0.1-35", repos = "http://cran.us.r-project.org")
#install.packages('tm')
#install.packages('topicmodels')
library(topicmodels)
library(tm)

dt_mat = as.DocumentTermMatrix(m, weighting=weightTf)
system.time(lda_mod <- LDA(dt_mat, 15)) # just 26min!!


save(lda_mod, file="data/rdata/lda_mod.rdata")

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

# This looks fun
#install.packages("LDAvis")
library(LDAvis)
#library(tsne)


pokemon_topics_data = list(
  phi   = posterior(lda_mod)$terms,
  theta = posterior(lda_mod)$topics,
  doc.length = rowSums(m_dense),
  vocab = colnames(posterior(lda_mod)$terms),
  term.frequency = colSums(m_dense)
)

json <- with(pokemon_topics_data, 
             createJSON(phi = phi, 
                        theta = theta, 
                        vocab = vocab,
                        doc.length = doc.length, 
                        term.frequency = term.frequency
                        #,mds.method = tsne
                        #,mds.method = function(x) tsne(svd(x)$u)
                        ))

#install.packages('servr')
serVis(json, out.dir = "vis", open.browser = TRUE)



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
