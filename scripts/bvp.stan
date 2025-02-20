data {
  int<lower=1> num_clubs;                           // number of clubs
  int<lower=1> num_games;                           // number of games
  int<lower=1,upper=num_clubs> home[num_games];     // home club for game g
  int<lower=1,upper=num_clubs> away[num_games];     // away club for game g
  int<lower=0> h_goals[num_games];                  // home goals for game g
  int<lower=0> a_goals[num_games];                  // away goals for game g
  int<lower=0,upper=1> homeg[num_games];            // home field for game g
   int<lower=0> np; //number of predicted games
  int<lower=0> htnew[np]; //home team index for prediction
  int<lower=0> atnew[np]; //away team index for prediction
}
parameters {
  vector[num_clubs] raw_alpha;                  // attacking intercepts
  vector[num_clubs] raw_delta;                  // defending intercepts
  vector[num_clubs] raw_rho;                    // covariance intercepts

  real mu;                                          // fixed intercept
  real eta;                                         // homefield
  real<lower=0> sigma_a;                            // attacking sd
  real<lower=0> sigma_d;                            // defending sd
  real<lower=0> sigma_r;                            // covariance sd
}
transformed parameters {
  vector[num_clubs] alpha;
  vector[num_clubs] delta;
  vector[num_clubs] rho;
  
  alpha = raw_alpha * sigma_a;
  delta = raw_delta * sigma_d;
  rho = raw_rho * sigma_r;
}
model {
  vector[num_games] lambda1;
  vector[num_games] lambda2;
  vector[num_games] lambda3;

  // priors
  raw_alpha ~ normal(0, 1);
  raw_delta ~ normal(0, 1);
  raw_rho ~ normal(0, 1);
  mu ~ normal(0, 10);
  eta ~ normal(0, 10);
  sigma_a ~ normal(0, 10);
  sigma_d ~ normal(0, 10);
  sigma_r ~ normal(0, 10);

  // likelihood
  for (g in 1:num_games) {
    lambda1[g] = exp(mu + (eta * homeg[g]) + alpha[home[g]] + delta[away[g]]);
    lambda2[g] = exp(mu + alpha[away[g]] + delta[home[g]]);
    lambda3[g] = exp(rho[home[g]] + rho[away[g]]);
  }
  h_goals ~ poisson(lambda1 + lambda3);
  a_goals ~ poisson(lambda2 + lambda3);
}

generated quantities {
//generate predictions
  vector[np] lambda1new; //score probability of home team
  vector[np] lambda2new; //score probability of away team
   vector[np] lambda3new;
  real s1new[np]; //predicted score
  real s2new[np]; //predicted score

for (g in 1:np) {
    lambda1new[g] = exp(mu + (eta * homeg[g]) + alpha[htnew[g]] + delta[atnew[g]]);
    lambda2new[g] = exp(mu + alpha[atnew[g]] + delta[htnew[g]]);
    lambda3new[g] = exp(rho[htnew[g]] + rho[atnew[g]]);
  }

  s1new = poisson_rng(lambda1new + lambda3new);
  s2new = poisson_rng(lambda2new + lambda3new);
}




