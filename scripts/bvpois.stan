data {
  int<lower=0> nt; //number of teams
  int<lower=0> ng; //number of games
  int<lower=0> ht[ng]; //home team index
  int<lower=0> at[ng]; //away team index
  int<lower=0> s1[ng]; //score home team
  int<lower=0> s2[ng]; //score away team
  int<lower=0> np; //number of predicted games
  int<lower=0> htnew[np]; //home team index for prediction
  int<lower=0> atnew[np]; //away team index for prediction
}

parameters {
  real home; //home advantage
  vector[nt] att; //attack ability of each team
  vector[nt] def; //defence ability of each team
  vector[nt] b_team; // Covariance term contributed by each team
   //vector[nt] b_away; // Covariance term contributed by away team
   real b_con;
  //hyper parameters
  real mu_att;
  real<lower=0> tau_att;
  real mu_def;
  real<lower=0> tau_def;
  real mu_b_team;
   real<lower=0> tau_b_team;
  
}

transformed parameters {
  
}

model {
  vector[ng] theta1; //score probability of home team
  vector[ng] theta2; //score probability of away team
  vector[ng] theta3; // covariance parameter in the game
//hyper priors
mu_att ~ normal(0,0.1);
tau_att ~ normal(0,1);
mu_def ~ normal(0,.1);
tau_def ~ normal(0,1);
mu_b_team ~ normal(0,0.01);
tau_b_team ~ normal(0,1); 
//priors
att ~ normal(mu_att, tau_att);
def ~ normal(mu_def, tau_def);
home ~ normal(0,0.1);
b_con ~ normal(0,0.1);
b_team ~ normal(mu_b_team,tau_b_team);



  for (g in 1:ng){
  theta1[g] = exp(home + att[ht[g]] - def[at[g]]);
  theta2[g] = exp(att[at[g]] - def[ht[g]]);
  theta3[g] = b_con + b_team[ht[g]] + b_team[at[g]]; // Change this to control covariance
  }
  s1 ~ poisson(theta1 + theta3);
  s2 ~ poisson(theta2 + theta3);
}


generated quantities {
//generate predictions
  vector[np] theta1new; //score probability of home team
  vector[np] theta2new; //score probability of away team
  vector[np] theta3new;
  real s1new[np]; //predicted score
  real s2new[np]; //predicted score


  for (g in 1:np){
  theta1new[g] = exp(home + att[ht[g]] - def[at[g]]);
  theta2new[g] = exp(att[at[g]] - def[ht[g]]);
  theta3new[g] = b_con + b_team[ht[g]] + b_team[at[g]]; // Change this to control covariance
  }
  s1new = poisson_rng(theta1new + theta3new);
  s2new = poisson_rng(theta2new + theta3new);
}
