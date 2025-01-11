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
  //hyper parameters
  real mu_att;
  real<lower=0> tau_att;
  real mu_def;
  real<lower=0> tau_def;
}

transformed parameters {
  // vector[ng] theta1; //score probability of home team
  // vector[ng] theta2; //score probability of away team
  // 
  // theta1 = exp(home + att[ht] - def[at]);
  // theta2 = exp(att[at] - def[ht]);

}

model {
  vector[ng] theta1; //score probability of home team
  vector[ng] theta2; //score probability of away team
  vector[ng] theta3; // covariance parameter in the game
//hyper priors
mu_att ~ normal(0,0.1);
tau_att ~ normal(0,1);
mu_def ~ normal(0,0.1);
tau_def ~ normal(0,1);

//priors
att ~ normal(mu_att, tau_att);
def ~ normal(mu_def, tau_def);
home ~ normal(0,0.1);


//likelihood
    // s1 ~ poisson(theta1);
    // s2 ~ poisson(theta2);
    for (g in 1:ng){
  theta1[g] = exp(home + att[ht[g]] - def[at[g]]);
  theta2[g] = exp(att[at[g]] - def[ht[g]]); // Change this to control covariance
  }
  s1 ~ poisson(theta1);
  s2 ~ poisson(theta2);
}



generated quantities {
//generate predictions
  vector[np] theta1new; //score probability of home team
  vector[np] theta2new; //score probability of away team
  real s1new[np]; //predicted score
  real s2new[np]; //predicted score


  for (g in 1:np){
  theta1new[g] = exp(home + att[ht[g]] - def[at[g]]);
  theta2new[g] = exp(att[at[g]] - def[ht[g]]);
 // Change this to control covariance
  }
  s1new = poisson_rng(theta1new);
  s2new = poisson_rng(theta2new);
}

