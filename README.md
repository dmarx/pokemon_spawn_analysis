Source:
  https://www.reddit.com/r/pokemongodev/comments/51pfvh/large_pokemon_spawn_dump/
  
Prior work:
  https://www.reddit.com/r/pokemongodev/comments/51x2lj/data_mining_500_000_pokemon_spawns_and_encounters/
  
Ideas:
  1. Clustering: What are the biomes? Do certain species of pokemon spawn together? 
  -- LDA: treat biomes as latent variables that generate spawn points
     with their own associated spawn percentages. Allows for spawns
     as mixtures of biomes.
  2. Association rules: GIven that we've observed a particular set of pokemon spawning, can we predict what rares might also spawn?
  3. Sequence mining (assumes census data which we probably don't have): given the pokemon we've observed, can we predict what the next spawn will be?
  4. Migration analysis: Are there any inferences we can draw about how spawns are likely to change after a migration? Can we predict what spawn points will change and what the new pokemon might be?

Update - New larger dataset available: 
  * https://www.reddit.com/r/TheSilphRoad/comments/532n4f/how_nests_actually_work_frequency_of_evolved/
  * https://drive.google.com/file/d/0B3QkZRzWUuWmVlQ4d1Vqel9PckE/view

18k spawnpoints with >100 spawns associated. Canberra, AUS. Courtesy of /u/saintmagician.