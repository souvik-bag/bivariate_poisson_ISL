library(tidyverse) 
library(StatsBombR) 
library(dplyr)
library(rstan)
# Comp <- FreeCompetitions() %>% filter(competition_id==1238 & season_id == 108) 
# Matches <- FreeMatches(Comp) 
# StatsBombData <- free_allevents(MatchesDF = Matches, Parallel = T) 
#  StatsBombData = allclean(StatsBombData) #5
# 
# data <- write.csv(Matches, "ISL.csv")
# 
# Matches <- Matches %>% select("home_score","away_score","home_team.home_team_name","away_team.away_team_name") %>% 
#    rename("away_team" = "away_team.away_team_name", "home_team" = "home_team.home_team_name")
#  
 
ISL <- read.csv("ISL.csv")

ng = nrow(ISL)
cat('we have G =', ng, 'games \n')

nt = length(unique(ISL$home_team))
cat('we have T = ', nt, 'teams \n')

# Plot the total number of goals scored and conceded
total_goals <- ISL %>%
  group_by(Team = home_team) %>%
  summarise(TotalGoalsScored = sum(home_score),TotalGoalsConceded = sum(away_score)) %>%
  bind_rows(ISL %>%
              group_by(Team = away_team) %>%
              summarise(TotalGoalsScored = sum(away_score),TotalGoalsConceded = sum(home_score))) %>%
  group_by(Team) %>%
  summarise(TotalGoalsScored = sum(TotalGoalsScored),TotalGoalsConceded = sum(TotalGoalsConceded))

## Plot

# Reshape data for plotting
plot_data <- reshape2::melt(total_goals, id.vars = "Team", measure.vars = c("TotalGoalsScored", "TotalGoalsConceded"))

# Barplot
ggplot(plot_data, aes(x = Team, y = value, fill = variable)) +
  geom_bar(stat = "identity", position = "dodge", color = "black") +
  labs(title = "Total Goals Scored and Conceded by each Team in ISL 2021-22",
       x = "Team", y = "Total Goals") +
  scale_fill_manual(values = c("TotalGoalsScored" = "blue", "TotalGoalsConceded" = "red")) +
  theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))



# data preparation for stan

teams = unique(ISL$home_team)
ht = unlist(sapply(1:ng, function(g) which(teams == ISL$home_team[g])))
at = unlist(sapply(1:ng, function(g) which(teams == ISL$away_team[g])))
ISL$home_game <- 1
# we will save the last 5 games to predict
np=5
ngob = ng-np #number of games to fit

my_data = list(
  num_clubs = nt, 
  num_games = ngob,
  home = ht[1:ngob], 
  homeg = ISL$home_game[1:ngob],
  away = at[1:ngob], 
  h_goals = ISL$home_score[1:ngob],
  a_goals = ISL$away_score[1:ngob],
  np = np,
  htnew = ht[(ngob+1):ng],
  atnew = at[(ngob+1):ng]
)

# Our data to fit in stan
my_data2 = list(
  nt = nt, 
  ng = ngob,
  ht = ht[1:ngob], 
  at = at[1:ngob], 
  s1 = ISL$home_score[1:ngob],
  s2 = ISL$away_score[1:ngob],
  np = np,
  htnew = ht[(ngob+1):ng],
  atnew = at[(ngob+1):ng]
)

# The stan models
nhfit = stan(file = 'bvpois.stan', data = my_data2, iter = 6000, chains= 5) # Bivariate poisson
pairs(nhfit, pars=c('mu_att', 'tau_att', 'mu_def', 'tau_def'))
hfit = stan(file = 'hier_model.stan', data = my_data2, iter = 6000,chains= 5) # Double poisson
pairs(hfit, pars=c('mu_att', 'tau_att', 'mu_def', 'tau_def'))
# Gelman-Rubin statistic
print(summary(nhfit)$summary[, "Rhat"])# Bivariate poisson
print(summary(hfit)$summary[, "Rhat"])# Double poisson
# trace plot
stan_trace(nhfit)
stan_trace(hfit)
#
par(mfrow = c(1, 1)) 
stan_dens(nhfit, pars = c("home","att[1]","def[1]"), title = "Posterior density of first 10 parameters in bivariate poisson model")
stan_dens(hfit,pars = c("home","att[1]","def[1]"), fill = "blue",main = "Posterior density of first 10 parameters in double poisson model")



# extract parameters and do the plots of posterior predictions and estimates

nhparams = extract(nhfit)
pred_scores_bvp = c(colMeans(nhparams$s1new),colMeans(nhparams$s2new))
true_scores_bvp = c(ISL$home_score[(ngob+1):ng],ISL$away_score[(ngob+1):ng] )
plot(true_scores_bvp, pred_scores_bvp, xlim=c(0,5), ylim=c(0,5), pch=20, ylab='predicted scores', xlab='true scores')
abline(a=0,  b=1, lty='dashed')

pred_errors = c(sapply(1:np, function(x) sd(nhparams$s1new[,x])),sapply(1:np, function(x) sd(nhparams$s1new[,x])))
arrows(true_scores, pred_scores+pred_errors, true_scores, pred_scores-pred_errors, length = 0.05, angle = 90, code = 3, col=rgb(0,0,0,0.3))

# Attack and deffence mean and sd for BVP
attack_bvp = colMeans(nhparams$att)
attacksd_bvp = sapply(1:nt, function(x) sd(nhparams$att[,x]))
defense_bvp = colMeans(nhparams$def)
defensesd_bvp = sapply(1:nt, function(x) sd(nhparams$def[,x]))

plot(attack_bvp,defense_bvp, xlim=c(-0.3,0.6), ylim=c(-0.5,0.5), pch=20,xlab = "Attack",ylab = "Defense", main = "Bivariate Poisson")
arrows(attack_bvp-attacksd_bvp, defense_bvp, attack_bvp+attacksd_bvp, defense_bvp, code=3, angle = 90, length = 0.04, col=rgb(0,0,0,0.2))
arrows(attack_bvp, defense_bvp-defensesd_bvp, attack_bvp, defense_bvp+defensesd_bvp, code=3, angle = 90, length = 0.04,col=rgb(0,0,0,0.2))
abline(h=0)
abline(v=0)
text(attack_bvp,defense_bvp, labels=teams, cex=0.7, adj=c(-0.05,-0.8) )



# Double poisson


hparams = extract(hfit)
pred_scores_dp = c(colMeans(hparams$s1new),colMeans(hparams$s2new))
pred_errors_dp = c(sapply(1:np, function(x) sd(hparams$s1new[,x])),sapply(1:np, function(x) sd(hparams$s1new[,x])))
true_scores =c(ISL$home_score[(ngob+1):ng],ISL$away_score[(ngob+1):ng] )
plot(true_scores, pred_scores_dp, xlim=c(0,5), ylim=c(0,5), pch=20, ylab='predicted scores', xlab='true scores')
abline(a=0,  b=1, lty='dashed')
arrows(true_scores, pred_scores_dp+pred_errors_dp, true_scores, pred_scores_dp-pred_errors_dp, length = 0.05, angle = 90, code = 3, rgb(0,0,0,0.3))

# Attack and deffence mean and sd for DP
attack_dp = colMeans(hparams$att)
attacksd_dp = sapply(1:nt, function(x) sd(hparams$att[,x]))
defense_dp = colMeans(hparams$def)
defensesd_dp = sapply(1:nt, function(x) sd(hparams$def[,x]))

plot(attack_dp,defense_dp, xlim=c(-0.3,0.6), ylim=c(-0.5,0.5), pch=20,xlab = "Attack",ylab = "Defense", main = "Double Poisson")
arrows(attack_dp-attacksd_dp, defense_dp, attack_dp+attacksd_dp, defense_dp, code=3, angle = 90, length = 0.04, col=rgb(0,0,0,0.2))
arrows(attack_dp, defense_dp-defensesd_dp, attack_dp, defense_dp+defensesd_dp, code=3, angle = 90, length = 0.04,col=rgb(0,0,0,0.2))
abline(h=0)
abline(v=0)
text(attack_dp,defense_dp, labels=teams, cex=0.7, adj=c(-0.05,-0.8) )




###Plot

# Combine data into a data frame
data_scores <- data.frame(True_Scores = true_scores, BVP = pred_scores_bvp, DP = pred_scores_dp)
library(ggplot2)
# Create a scatter plot
ggplot(data_scores, aes(x = True_Scores)) +
  geom_point(aes(y = BVP), color = "red", shape = 16,size = 3) +
  geom_point(aes(y = DP), color = "blue", shape = 16,size = 3) +
  labs(title = "True vs Predicted Scores",
       x = "True Scores",
       y = "Predicted Scores") +
  theme_minimal()









