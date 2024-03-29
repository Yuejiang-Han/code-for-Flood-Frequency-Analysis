#======================= package =====================================
install.packages("readxl")
install.packages("fitdistrplus")
install.packages("ggpmisc")
install.packages("dgof")
install.packages("goftest")
install.packages("pracma")
install.packages("moments")
install.packages("PearsonDS")
install.packages("EnvStats")
install.packages("univariateML")
install.packages("lcc" )
install.packages("tidyverse" )
install.packages("GoFKernel")
install.packages("FAdist")
install.packages("broom")
install.packages("nsRFA")
install.packages("Metrics")
install.packages("FlomKartShinyApp")
install.packages("caret")

library(readxl) #为了读取excel的数据
library(MASS)
library(fitdistrplus)
library(ggplot2) 
library(ggpmisc) 
library(lmomco)
library(lmom)
library(moments)
library(pracma)
library(PearsonDS)
library(EnvStats)
library(univariateML)
library(lcc)
library(ggplot2)
library(tidyverse)
library(GoFKernel)
library(broom)
library(nsRFA)
library(Metrics)
library(goftest)
library(caret)
data5$Year
#======================= checking data======================================
sheets <- excel_sheets("C:\\Users\\26752\\Desktop\\1.xlsx");sheets
data <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "ash")
summary(data$`Flow(m^3/s)`)
year <- data$Date
x <- data$`Flow(m^3/s)`
# x[is.na(x)] <- mean(x, na.rm = TRUE)
y <- data$Year
barplot(x,
        names.arg = data$`Water Year`,
        main = "Wye Water at redbrook", 
        xlab = "Year", 
        ylab = "Flow",
        col = "blue")
plot(density(x)) ## PDF
plot(ecdf(x),main="Empirical cumulative distribution function") ## CDF

#======================= Sort data ==============================
Xi <- sort(data$`Flow(m^3/s)`)

# Checking Outlier 
# The Grubbs and Beck (1972) test (G-B) may be used to detect outliers
boxplot(Xi, main = "Boxplot for Redbrook Station Flow")
outliers_positions <-  function(Xi){
  # （IQR）
  IQR <- quantile(Xi, 0.75) - quantile(Xi, 0.25)
  
  # bound
  upper_bound <- quantile(Xi, 0.75) + 1.5 * IQR
  lower_bound <- quantile(Xi, 0.25) - 1.5 * IQR
  
  # get index for outlier
  outliers_positions <- which(Xi > upper_bound | Xi < lower_bound)
  
  # Print outlier
  return(outliers_positions)
  
}
outliers_positions<- outliers_positions(Xi)
 




#======================= Cleaning data ==============================
if (length(outliers_positions)>0){
  Xi <- Xi[-outliers_positions]
}


df <- data.frame(i = numeric(0), X=numeric(0),F = numeric(0),T = numeric(0))

N = length(Xi)
N = 100
#Ploting position with Return period

for (i in 1:length(Xi)) {
  X <- Xi[i]
  F <- i / (1 + length(Xi))
  T <- 1/(1-F)
  df <- rbind(df, data.frame(i = i,X, F = F, T = T))
}

if (length(Xi) +1< N){
  for (i in (length(Xi)+1) :N) {
    X <- NA
    T <- i + 1
    F <- 1-1/T
    df <- rbind(df, data.frame(i = i,X, F = F, T = T))
  }
}


#======================= Normal Family===================================

# Fit data to a normal distribution
fit_norm_mom <- fitdist(Xi, distr = "norm", method = "mme"); fit_norm_mom

fit_norm_mle <- fitdist(Xi, distr = "norm", method = "mle"); fit_norm_mle

fit_norm_pwm <- lmom2par(lmoms(Xi),type="nor");fit_norm_pwm


# Fit data to a LN[2] distribution
fit_LN2_mom <- fitdist(Xi, distr = "lnorm", method = "mme"); fit_LN2_mom

fit_LN2_mle <- fitdist(Xi, distr = "lnorm", method = "mle"); fit_LN2_mle

LN2_pwm <- function(data){
  pwm <- pwm(Xi, 2)
  b0 = pwm$betas[1]; b1 = pwm$betas[2]
  l1 = b0 ; l2 = 2*b1 - b0
  t = l2/l1
  sigma_est <- 2*erfinv(t)
  mu_est <- log(l1) - sigma_est^2/2
  return(list(mu_est = mu_est, sigma_est = sigma_est))
}

fit_LN2_pwm <- LN2_pwm(Xi);fit_LN2_pwm

# Fit data to a LN[3] distribution

fit_LN3_mom <- elnorm3(Xi, method = "mme"); fit_LN3_mom

fit_LN3_mle <- elnorm3(Xi, method = "lmle"); fit_LN3_mle

fit_LN3_pwm <- lmom2par(lmoms(Xi),type="ln3");fit_LN3_pwm



#======================= Gamma Family =================================

# Fit data to a Exp distribution
fit_exp_mom <- fitdist(Xi, distr = "exp", method = "mme"); fit_exp_mom

fit_exp_mle <- fitdist(Xi, distr = "exp", method = "mle"); fit_exp_mle

fit_exp_pwm <- fitdist(Xi, distr = "exp", method = "mme"); fit_exp_pwm

# only use this when fitdist is not working

log_likelihood_exp <- function(lambda, data) {
  n <- length(data)
  ll <- n * log(lambda) - lambda * sum(data)
  return(-ll) 
}

# use optim to find mle
result <- optim(par = 1, fn = log_likelihood_exp, data = Xi, method = "BFGS") 
fit_exp_mle$estimate <- result$par



# Fit data to a Gamma distribution
fit_gamma_mom <- fitdist(Xi, distr = "gamma", method = "mme"); fit_gamma_mom

fit_gamma_mle <- fitdist(Xi, distr = "gamma", method = "mle"); fit_gamma_mle

fit_gamma_pwm <- lmom2par(lmoms(Xi),type="gam"); fit_gamma_pwm

rate_gamma_pwm = 1/fit_gamma_pwm$para[2];rate_gamma_pwm

# Fit data to a PIII distribution

PIII_mom <- function(data){
  m1 = mean(data)
  m2 = var(data)
  cs = skewness(data)
  Beta_est = (2/cs)^2
  alpha_est = sqrt(m2/Beta_est)
  gamma_est = m1 - sqrt(m2*Beta_est)
  return(list(alpha_est = alpha_est, Beta_est = Beta_est, gamma_est = gamma_est))
}



fit_pe3_mom <- moment_estimation(Xi,"P3"); fit_pe3_mom

fit_pe3_momp <- par2mom.gamma(fit_pe3_mom[1],fit_pe3_mom[2],fit_pe3_mom[3])

fit_pe3_momp <- mom2par.gamma(fit_pe3_mom[1],fit_pe3_mom[2],fit_pe3_mom[3])

fit_pe3_mle <- ML_estimation(Xi,"P3"); fit_pe3_mle

fit_pe3_mlep <- mom2par.gamma(fit_pe3_mle[1],fit_pe3_mle[2],fit_pe3_mle[3])

fit_pe3_pwm <- lmom2par(lmoms(Xi),type="pe3"); fit_pe3_pwm



# Fit data to a log_PIII distribution


fit_lpe3_mom <- moment_estimation(log(Xi),"P3"); fit_lpe3_mom

fit_lpe3_mle <- ML_estimation(log(Xi),"P3"); fit_lpe3_mle

fit_lpe3_pwm <- lmom2par(lmoms(log(Xi)),type="pe3"); fit_lpe3_pwm

par2mom.gamma (fit_lpe3_mom[1],fit_lpe3_mom[2],fit_lpe3_mom[3])

#======================= GEV Family ====================================

fit_gev_mom <- moment_estimation(Xi, "GEV"); fit_gev_mom

fit_gev_mle <- ML_estimation(Xi, "GEV"); fit_gev_mle

fit_gev_pwm <- lmom2par(lmoms(Xi),type="gev"); fit_gev_pwm



# Fit data to a EV1 distribution 
fit_ev1_mom <-  eevd(Xi,method = "mme");fit_ev1_mom

fit_ev1_mle <- eevd(Xi,method = "mle");fit_ev1_mle

fit_ev1_pwm <- lmom2par(lmoms(Xi),type="gum");fit_ev1_pwm

# Fit data to a Weibull distribution 
fit_weibull_mom <- eweibull(Xi, method = "mme");fit_weibull_mom

fit_weibull_mle <- eweibull(Xi, method = "mle");fit_weibull_mle

fit_weibull_pwm <- lmom2par(lmoms(Xi),type="wei");fit_weibull_pwm




#======================= Fit  ======================================
# # 
# fit_norm_mom
# fit_norm_mle
# fit_norm_pwm
# 
# fit_LN2_mom
# fit_LN2_mle
# fit_LN2_pwm
# 
# fit_LN3_mom
# fit_LN3_mle
# fit_LN3_pwm
# 
# fit_exp_mom
# fit_exp_mle
# fit_exp_pwm
# 
# fit_gamma_mom
# fit_gamma_mle
# fit_gamma_pwm
# 
# fit_pe3_mom
# fit_pe3_mle
# fit_pe3_pwm
# 
# fit_lpe3_mom
# fit_lpe3_mle
# fit_lpe3_pwm
# 
# fit_gev_mom
# fit_gev_mle
# fit_gev_pwm
# 
# fit_ev1_mom
# fit_ev1_mle
# fit_ev1_pwm
# 
# fit_weibull_mom
# fit_weibull_mle
# fit_weibull_pwm

pT = df[,3]


#___________________________________ Norm ______________________________________
norm_mom= qnorm(pT,mean = fit_norm_mom$estimate[1], sd = fit_norm_mom$estimate[2])

norm_mle <- qnorm(pT,mean = fit_norm_mle$estimate[1], sd = fit_norm_mle$estimate[2])

norm_pwm <- qnorm(pT,mean = fit_norm_pwm$para[1], sd = fit_norm_pwm$para[2])


#___________________________________ LN2 _______________________________________

ln2_mom <- qlnorm(pT, meanlog = fit_LN2_mom$estimate[1], sdlog = fit_LN2_mom$estimate[2])

ln2_mle <- qlnorm(pT, meanlog = fit_LN2_mle$estimate[1], sdlog = fit_LN2_mle$estimate[2])

ln2_pwm <- qlnorm(pT, meanlog = fit_LN2_pwm$mu_est, sdlog = fit_LN2_pwm$sigma_est)

#___________________________________ LN3 _______________________________________

detach("package:FAdist", unload = TRUE)

ln3_mom <- qlnorm3(pT, 
                   meanlog = fit_LN3_mom$parameters[1], 
                   sdlog = fit_LN3_mom$parameters[2],
                   threshold = fit_LN3_mom$parameters[3])

ln3_mle <- qlnorm3(pT, 
                   meanlog = fit_LN3_mle$parameters[1], 
                   sdlog = fit_LN3_mle$parameters[2],
                   threshold = fit_LN3_mle$parameters[3])

ln3_pwm <- qlnorm3(pT, 
                   meanlog = fit_LN3_pwm$para[2], 
                   sdlog = fit_LN3_pwm$para[3],
                   threshold = fit_LN3_pwm$para[1])


#___________________________________ exp _______________________________________
    
exp_mom <- qexp(pT, rate = fit_exp_mom$estimate)

exp_mle <- qexp(pT, rate = fit_exp_mle$estimate)

exp_pwm <- qexp(pT, rate = fit_exp_pwm$estimate)


#___________________________________ Gamma _____________________________________

gamma_mom <- qgamma(pT,shape = fit_gamma_mom$estimate[1], rate = fit_gamma_mom$estimate[2])

gamma_mle <- qgamma(pT,shape = fit_gamma_mle$estimate[1], rate = fit_gamma_mle$estimate[2])

gamma_pwm <- qgamma(pT,shape = fit_gamma_pwm$para[1], rate = 1/fit_gamma_pwm$para[2])



#___________________________________ pe3 _______________________________________

pe3_mom <- qpearsonIII(pT,
                       shape = fit_pe3_mom[3],
                       location = fit_pe3_mom[1],
                       scale = fit_pe3_mom[2])
# 
# pe3_momp <- qpearsonIII(pT, 
#                        shape = fit_pe3_momp$gamm,
#                        location = fit_pe3_momp$mu,
#                        scale = fit_pe3_momp$sigma)


pe3_mle <- qpearsonIII(pT,
                       shape = fit_pe3_mle[3],
                       location = fit_pe3_mle[1],
                       scale = fit_pe3_mle[2])

# pe3_mle <- qpearsonIII(pT, 
#                        shape = fit_pe3_mle$gamm,
#                        location = fit_pe3_mle$mu,
#                        scale = fit_pe3_mle$sigma)

pe3_pwm <- qpearsonIII(pT, shape = fit_pe3_pwm$para[3],
            location = fit_pe3_pwm$para[1],
            scale = fit_pe3_pwm$para[2])


mom2par.gamma (mu=123.0647885, sigma=37.5078429, gamm=0.7442705)
#___________________________________ Lpe3 ______________________________________

lpe3_mom <- exp(invF.gamma(pT,fit_lpe3_mom[1], fit_lpe3_mom[2], fit_lpe3_mom[3]))

lpe3_mle <- exp(invF.gamma(pT,fit_lpe3_mle[1], fit_lpe3_mle[2], fit_lpe3_mle[3]))

lpe3_pwm <-exp(invF.gamma(pT,fit_lpe3_pwm$para[1], fit_lpe3_pwm$para[2], fit_lpe3_pwm$para[3]))

#___________________________________ Gev _______________________________________

gev_mom <- qgevd(pT,
                 location = fit_gev_mom[1], 
                 scale = fit_gev_mom[2], 
                 shape = fit_gev_mom[3])

gev_mle <- qgevd(pT,
                 location = fit_gev_mle[1], 
                 scale = fit_gev_mle[2], 
                 shape = fit_gev_mle[3])

gev_pwm <- qgevd(pT,
                 location = fit_gev_pwm$para[1], 
                 scale = fit_gev_pwm$para[2], 
                 shape = fit_gev_pwm$para[3])


#___________________________________ ev1 _______________________________________
ev1_mom <- qevd(pT, location = fit_ev1_mom$parameters[1], scale = fit_ev1_mom$parameters[2])

ev1_mle <- qevd(pT, location = fit_ev1_mle$parameters[1], scale = fit_ev1_mle$parameters[2])

ev1_pwm <- qevd(pT, location = fit_ev1_pwm$para[1], scale = fit_ev1_pwm$para[2])



#___________________________________ weibull____________________________________

wei_mom <- qweibull(pT, shape = fit_weibull_mom$parameters[1], scale = fit_weibull_mom$parameters[2])

wei_mle <- qweibull(pT, shape = fit_weibull_mle$parameters[1], scale = fit_weibull_mle$parameters[2])

wei_pwm <- qweibull(pT, shape = fit_weibull_pwm$para[3], scale = fit_weibull_pwm$para[2]) - fit_weibull_pwm$para[1]

# "norm", "ln2", "ln3", "exp", "gamma", "pe3","lpe3", "gev", "ev1", "wei"
ddd <- data.frame()
ddd <- data.frame(df, 
                  norm_mom, norm_mle, norm_pwm, 
                  ln2_mom, ln2_mle, ln2_pwm,
                  ln3_mom, ln3_mle, ln3_pwm,
                  exp_mom, exp_mle, exp_pwm,
                  gamma_mom, gamma_mle, gamma_pwm,
                  pe3_mom, pe3_mle,pe3_pwm,
                  lpe3_mom, lpe3_mle,lpe3_pwm,
                  gev_mom, gev_mle, gev_pwm,
                  ev1_mom, ev1_mle, ev1_pwm,
                  wei_mom, wei_mle, wei_pwm) 
#======================= Plot ======================================

# p <- ggplot(data = ddd, mapping = aes(x = T, y = X)) +
#   geom_point(aes(color = "Observation"), size = 2) + 
#   scale_color_manual(values = c("Observation" = "black")) +  # 这里可以改变颜色
#   ggtitle("Observation from ash station data") +
#   xlab("Return Period(Years)") + 
#   ylab("Flow Rate(m^3/s)")
# 
# p
ddd[1:5]
p <- ggplot(data = ddd,
            mapping = aes(
              x = T,
              y = X))

p + 
  # ggtitle("Observation V.S. Fitting Model for Redbrook Station ") +
  ggtitle("Observation V.S. Fitting Model for Ash Station over 100 Years") +
  xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
  geom_point(size = 2) +
  
  # geom_line(aes(x = T, y = norm_mom, color = "norm_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = norm_mle, color = "norm_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = norm_pwm, color = "norm_lmom" ), size = 1.023) +

  # geom_line(aes(x = T, y = ln2_mom, color = "ln2_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = ln2_mle, color = "ln2_mle" ), size = 1.023) +
  geom_line(aes(x = T, y = ln2_pwm, color = "ln2_lmom" ), size = 1.023) +

  # geom_line(aes(x = T, y = ln3_mom, color = "ln3_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = ln3_mle, color = "ln3_mle" ), size = 1.023) +
  geom_line(aes(x = T, y = ln3_pwm, color = "ln3_lmom" ), size = 1.023) +

  # geom_line(aes(x = T, y = exp_mom, color = "exp_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = exp_mle, color = "exp_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = exp_pwm, color = "exp_lmom" ), size = 1.023) +
  # 
  # geom_line(aes(x = T, y = gamma_mom, color = "gamma_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = gamma_mle, color = "gamma_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = gamma_pwm, color = "gamma_lmom" ), size = 1.023) +
  # 
  # geom_line(aes(x = T, y = pe3_mom, color = "pe3_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = pe3_mle, color = "pe3_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = pe3_pwm, color = "pe3_lmom" ), size = 1.023) +
  # 
  # geom_line(aes(x = T, y = lpe3_mom, color = "lpe3_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = lpe3_mle, color = "lpe3_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = lpe3_pwm, color = "lpe3_lmom" ), size = 1.023) +
  # 
  # geom_line(aes(x = T, y = gev_mom, color = "gev_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = gev_mle, color = "gev_mle" ), size = 1.023) +
  # geom_line(aes(x = T, y = gev_pwm, color = "gev_lmom" ), size = 1.023) +

  # geom_line(aes(x = T, y = ev1_mom, color = "ev1_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = ev1_mle, color = "ev1_mle" ), size = 1.023) +
  geom_line(aes(x = T, y = ev1_pwm, color = "ev1_lmom" ), size = 1.023) 

  # geom_line(aes(x = T, y = wei_mom, color = "wei_mom" ), size = 1.023) +
  # geom_line(aes(x = T, y = wei_mle, color = "wei_mle" ), size = 1.023) + 
  # geom_line(aes(x = T, y = wei_pwm, color = "wei_lmom" ), size = 1.023)



#============================ Goodness of fit ==================================

#=======================  KS Test ==============================================
ks_f <- function(x){
    
  ks_norm_mom <- ks.test(Xi,"pnorm", fit_norm_mom$estimate[1], 
                         fit_norm_mom$estimate[2])
  ks_norm_mle <- ks.test(Xi,"pnorm", fit_norm_mle$estimate[1], 
                         fit_norm_mle$estimate[2])
  ks_norm_pwm <- ks.test(Xi,"pnorm", fit_norm_pwm$para[1], 
                         fit_norm_pwm$para[2])
  
  
  ks_ln2_mom <- ks.test(Xi,"plnorm", fit_LN2_mom$estimate[1], 
                        fit_LN2_mom$estimate[2])
  ks_ln2_mle <- ks.test(Xi,"plnorm", fit_LN2_mle$estimate[1], 
                        fit_LN2_mle$estimate[2])
  ks_ln2_pwm <- ks.test(Xi,"plnorm", fit_LN2_pwm$mu_est, 
                        fit_LN2_pwm$sigma_est)
  
  ks_LN3_mom <- ks.test(Xi,"plnorm3", fit_LN3_mom$parameters[1], 
                        fit_LN3_mom$parameters[2],fit_LN3_mom$parameters[])
  ks_LN3_mle <- ks.test(Xi,"plnorm3", fit_LN3_mle$parameters[1], 
                        fit_LN3_mle$parameters[2],fit_LN3_mle$parameters[])
  ks_LN3_pwm <- ks.test(Xi,"plnorm3", fit_LN3_pwm$para[3], 
                        fit_LN3_pwm$para[1],fit_LN3_pwm$para[2])
  
  ks_exp_mom <- ks.test(Xi,"pexp", fit_exp_mom$estimate)
  ks_exp_mle <- ks.test(Xi,"pexp", fit_exp_mle$estimate)
  ks_exp_pwm <- ks.test(Xi,"pexp", fit_exp_pwm$estimate)
  
  ks_gamma_mom <- ks.test(Xi,"pgamma", fit_gamma_mom$estimate[1], 
                          fit_gamma_mom$estimate[2])
  ks_gamma_mle <- ks.test(Xi,"pgamma", fit_gamma_mle$estimate[1], 
                          fit_gamma_mle$estimate[2])
  ks_gamma_pwm <- ks.test(Xi,"pgamma", fit_gamma_pwm$para[1], 
                          fit_gamma_pwm$para[2])
  
  ks_pe3_mom <- ks.test(Xi,"ppearsonIII",  fit_pe3_mom[3], fit_pe3_mom[1], 
                        fit_pe3_mom[2])
  ks_pe3_mle <- ks.test(Xi,"ppearsonIII", fit_pe3_mle[3], fit_pe3_mle[1], 
                        fit_pe3_mle[2])
  ks_pe3_pwm <- ks.test(Xi,"ppearsonIII", fit_pe3_pwm$para[3], 
                        fit_pe3_pwm$para[1], fit_pe3_pwm$para[2])
  
  
  
  ks_lpe3_mom <- ks.test(log(Xi),"f.gamma", fit_lpe3_mom[1], fit_lpe3_mom[2], 
                         fit_lpe3_mom[3])
  ks_lpe3_mle <- ks.test(log(Xi),"f.gamma", fit_lpe3_mle[1], fit_lpe3_mle[2], 
                         fit_lpe3_mle[3]) 
  ks_lpe3_pwm <- ks.test(log(Xi),"f.gamma", fit_lpe3_pwm$para[3],fit_lpe3_pwm$para[2],
                         fit_lpe3_pwm$para[1])
  
  # ks_lpe3_mom <- ks.test(Xi,"plgamma3", fit_lpe3_mom[1], fit_lpe3_mom[2], 
  #                        fit_lpe3_mom[3])
  # ks_lpe3_mle <- ks.test(Xi,"plgamma3", fit_lpe3_mle[3], fit_lpe3_mle[1], 
  #                        fit_lpe3_mle[2]) 
  # ks_lpe3_pwm <- ks.test(Xi,"plgamma3", fit_lpe3_pwm$para[3],fit_lpe3_pwm$para[1],
  #                        fit_lpe3_pwm$para[2])
   
  ks_gev_mom <- ks.test(Xi,"pgevd", fit_gev_mom[1], fit_gev_mom[2], 
                        fit_gev_mom[3])
  ks_gev_mle <- ks.test(Xi,"pgevd", fit_gev_mle[1], 
                        fit_gev_mle[2], fit_gev_mle[3])
  ks_gev_pwm <- ks.test(Xi,"pgevd", fit_gev_pwm$para[1], fit_gev_pwm$para[2], 
                        fit_gev_pwm$para[3])
  
  ks_ev1_mom <- ks.test(Xi,"pevd", fit_ev1_mom$parameters[1], 
                        fit_ev1_mom$parameters[2])
  ks_ev1_mle <- ks.test(Xi,"pevd", fit_ev1_mle$parameters[1], 
                        fit_ev1_mle$parameters[2])
  ks_ev1_pwm <- ks.test(Xi,"pevd", fit_ev1_pwm$para[1], fit_ev1_pwm$para[2])
  
  ks_wei_mom <- ks.test(Xi,"pweibull", fit_weibull_mom$parameters[1], 
                        fit_weibull_mom$parameters[2])
  ks_wei_mle <- ks.test(Xi,"pweibull", fit_weibull_mle$parameters[1], 
                        fit_weibull_mle$parameters[2])
  ks_wei_pwm <- ks.test(Xi,"pweibull", fit_weibull_pwm$para[3], 
                        fit_weibull_pwm$para[2])
  
  ks <- c(ks_norm_mom$statistic, 
          ks_norm_mle$statistic,
          ks_norm_pwm$statistic,
          
          ks_ln2_mom$statistic, 
          ks_ln2_mle$statistic,
          ks_ln2_pwm$statistic,
          
          ks_LN3_mom$statistic, 
          ks_LN3_mle$statistic,
          ks_LN3_pwm$statistic,
          
          ks_exp_mom$statistic, 
          ks_exp_mle$statistic,
          ks_exp_pwm$statistic,
          
          ks_gamma_mom$statistic, 
          ks_gamma_mle$statistic,
          ks_gamma_pwm$statistic,
          
          ks_pe3_mom$statistic, 
          ks_pe3_mle$statistic,
          ks_pe3_pwm$statistic,
          
          ks_lpe3_mom$statistic, 
          ks_lpe3_mle$statistic,
          ks_lpe3_pwm$statistic,
          
          ks_gev_mom$statistic, 
          ks_gev_mle$statistic,
          ks_gev_pwm$statistic,
          
          ks_ev1_mom$statistic, 
          ks_ev1_mle$statistic,
          ks_ev1_pwm$statistic,
          
          ks_wei_mom$statistic, 
          ks_wei_mle$statistic,
          ks_wei_pwm$statistic)
  
  return(ks)
}

ks <- ks_f(Xi)
names(ks) <- NULL
ks <- round(ks, 3)
print(ks)
which.min(ks)

#gev_pwm
p + geom_line(aes(x = T, y = gev_pwm, color = "gev_mle" ), size = 2) + 
    ggtitle("Best Fit by KS Test") +
    xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
    geom_point(size = 2)


# ============================= AIC Test ========================================
compute_aic <- function(loglik, num_params) {
  # get AIC
  aic_value <- 2 * num_params - 2 * loglik
  # return AIC
  return(aic_value)
}


#norm
aic_norm <- AIC(fitdistr(Xi, "normal"))

#ln2
aic_ln2 <- AIC(fitdistr(Xi, "log-normal"))

# =========== ln3 
dlnorm3 <- function(x, meanlog = 0, sdlog = 1, threshold = 0) {
  dlnorm(x - threshold, meanlog, sdlog)
}

# function to get loglik for ln3
loglik_lnorm3 <- function(params, data) {
  meanlog <- params[1]
  sdlog <- params[2]
  threshold <- params[3]
  
  # get loglik 
  loglik <- sum(log(dlnorm3(data, meanlog, sdlog, threshold)))
  
  return(loglik)
}

loglik_ln3 <- loglik_lnorm3(fit_LN3_mle$parameters, Xi)


aic_ln3 <- compute_aic(loglik_ln3, length(fit_LN3_mle$parameters))

#exp
aic_exp <- AIC(fitdistr(Xi, "exponential"))

#gamma
aic_gamma <- AIC(fitdistr(Xi, "gamma"))

# =========== pe3 


# function to get loglik for pe3
loglik_pearson3 <- function(params, data) {
  shape <- params[3]
  scale <- params[2]
  location <- params[1]
  
  # get loglik
  loglik <- sum(log(dpearsonIII(data, shape, location, scale)))
  
  return(loglik)
}

loglik_pe3 <- loglik_pearson3(fit_pe3_mle, Xi)

aic_pe3 <- compute_aic(loglik_pe3, length(fit_pe3_mle))

# =========== lpe3 

# function to get pdf for lpe3
dlogpearson3 <- function(x, shape, location, scale ) {
  dpearsonIII(exp(x), shape, location, scale) * exp(x)
}

# function to get loglik for lpe3
loglik_lpearson3 <- function(params, data) {
  shape <- params[3]
  scale <- params[2]
  location <- params[1]
  
  # get loglik
  loglik <- sum(log(dlogpearson3(data, shape = shape, scale = scale, location = location) + 1e-10))
  
  return(loglik)
}


loglik_lpe3 <- loglik_lpearson3(fit_lpe3_mle, Xi);loglik_lpe3

aic_lpe3 <- compute_aic(loglik_lpe3, length(fit_lpe3_mle))

# =========== gev ==========

loglik_gev_f <- function(params, data) {
  location <- params[1]
  scale <- params[2]
  shape <- params[3]
  
  # get loglik
  loglik <- sum(log(dgev(data, location, scale, shape)))

  return(loglik)
}

loglik_gev <- loglik_gev_f(fit_gev_mle, Xi)

aic_gev <- compute_aic(loglik_gev, length(fit_gev_mle))

# =========== ev1  

loglik_evd <- function(params, data) {
  location <- params[1]
  scale <- params[2]
  
  # get loglik
  loglik <- sum(log(devd(data, location, scale)))

  return(loglik)
}

loglik_ev1 <- loglik_evd(fit_ev1_mle$parameters, Xi)

aic_ev1 <- compute_aic(loglik_ev1, length(fit_ev1_mle$parameters))

# weibull
aic_wei <- AIC(fitdistr(Xi, "weibull"))


aic <- c(aic_norm, aic_ln2, aic_ln3, aic_exp, aic_gamma, aic_pe3,
         aic_lpe3,
         aic_gev, aic_ev1, aic_wei)


which.min(aic) # aic_gamma is best

p + geom_line(aes(x = T, y = gev_pwm, color = "ln3_mle" ), size = 2) + 
  ggtitle("Best Fit by AIC") +
  xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
  geom_point(size = 2)

# ============================= BIC Test =======================================
compute_bic <- function(loglik, num_params, num_data) {
  bic <- -2 * loglik + num_params * log(num_data)
  return(bic)
}

#norm
bic_norm <- BIC(fitdistr(Xi, "normal"))

#ln2
bic_ln2 <- BIC(fitdistr(Xi, "log-normal"))

# =========== ln3 
bic_ln3 <- compute_bic(loglik_ln3, length(fit_LN3_mle$parameters), N)

#exp
bic_exp <- BIC(fitdistr(Xi, "exponential"))

#gamma
bic_gamma <- BIC(fitdistr(Xi, "gamma"))

# =========== pe3 
bic_pe3 <- compute_bic(loglik_pe3, length(fit_pe3_mle), N)

# =========== lpe3 

bic_lpe3 <- compute_bic(loglik_ln3, length(fit_lpe3_mle), N)

# =========== gev 
bic_gev <- compute_bic(loglik_gev, length(fit_gev_mle), N)

# =========== ev1  
bic_ev1 <- compute_bic(loglik_ev1, length(fit_ev1_mle$parameters), N)

# weibull
bic_wei <- BIC(fitdistr(Xi, "weibull"))


bic <- c(bic_norm, bic_ln2, bic_ln3, bic_exp, bic_gamma, bic_pe3,
         bic_lpe3,
         bic_gev, bic_ev1, bic_wei)
round(bic,3)

which.min(bic) # bic_gamma is best
p + geom_line(aes(x = T, y = ev1_mle, color = "ev1_mle" ), size = 2) + 
  ggtitle("Best Fit by BIC") +
  xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
  geom_point(size = 2)

#========================== RMSE ===============================================

# which distribution get min RMSE
rmse_f <- function(data, df = ddd){
  #prepare empty vector to save result
  rmse_result <- c()
  
  # loop 30 result 
  for (i in 5:34) {
    rmse_result <- rbind(rmse_result, round(rmse(data, df[,i]),3))
  }
  
  # use index by which min to get best distribution
  best <- colnames(df)[which.min(rmse_result)+4]
  return(c(rmse_result,best))
}


rmse_m <- function(predictions, observations) {
  sqrt(mean((predictions - observations)^2))
}


rmse_f(Xi, ddd)

p + geom_line(aes(x = T, y = wei_pwm, color = "wei_pwm" ), size = 2) + 
  ggtitle("Best Fit by RMSE") +
  xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
  geom_point(size = 2)

#======================= AD Test ===============================================

ad_f <- function(X){  
    
  ad_norm_mom <- ad.test(Xi,"pnorm", fit_norm_mom$estimate[1], 
                         fit_norm_mom$estimate[2])
  ad_norm_mle <- ad.test(Xi,"pnorm", fit_norm_mle$estimate[1], 
                         fit_norm_mle$estimate[2])
  ad_norm_pwm <- ad.test(Xi,"pnorm", fit_norm_pwm$para[1], 
                         fit_norm_pwm$para[2])
  
  ad_ln2_mom <- ad.test(Xi,"plnorm", fit_LN2_mom$estimate[1], 
                        fit_LN2_mom$estimate[2])
  ad_ln2_mle <- ad.test(Xi,"plnorm", fit_LN2_mle$estimate[1], 
                        fit_LN2_mle$estimate[2])
  ad_ln2_pwm <- ad.test(Xi,"plnorm", fit_LN2_pwm$mu_est, 
                        fit_LN2_pwm$sigma_est)
  
  detach("package:FAdist", unload = TRUE)
  ad_LN3_mom <- ad.test(Xi,"plnorm3", fit_LN3_mom$parameters[1], 
                        fit_LN3_mom$parameters[2],fit_LN3_mom$parameters[3])
  ad_LN3_mle <- ad.test(Xi,"plnorm3", fit_LN3_mle$parameters[1], 
                        fit_LN3_mle$parameters[2],fit_LN3_mle$parameters[3])
  ad_LN3_pwm <- ad.test(Xi,"plnorm3", fit_LN3_pwm$para[2], 
                        fit_LN3_pwm$para[3],fit_LN3_pwm$para[1])
  
  ad_exp_mom <- ad.test(Xi,"pexp", fit_exp_mom$estimate)
  ad_exp_mle <- ad.test(Xi,"pexp", fit_exp_mle$estimate)
  ad_exp_pwm <- ad.test(Xi,"pexp", fit_exp_pwm$estimate)
  
  ad_gamma_mom <- ad.test(Xi,"pgamma", fit_gamma_mom$estimate[1], 
                          fit_gamma_mom$estimate[2])
  ad_gamma_mle <- ad.test(Xi,"pgamma", fit_gamma_mle$estimate[1], 
                          fit_gamma_mle$estimate[2])
  ad_gamma_pwm <- ad.test(Xi,"pgamma", fit_gamma_pwm$para[1], 
                          1/fit_gamma_pwm$para[2])
  
  ad_pe3_mom <- ad.test(Xi,"ppearsonIII", fit_pe3_mom[3], fit_pe3_mom[2], 
                        fit_pe3_mom[1])
  ad_pe3_mle <- ad.test(Xi,"ppearsonIII", fit_pe3_mle[3], fit_pe3_mle[2], 
                        fit_pe3_mle[1])
  ad_pe3_pwm <- ad.test(Xi,"ppearsonIII", fit_pe3_pwm$para[3], 
                        fit_pe3_pwm$para[2], fit_pe3_pwm$para[1])
  
  library(FAdist)
  
  ad_lpe3_mom <- ad.test(log(Xi),"f.gamma", fit_lpe3_mom[1], fit_lpe3_mom[2], 
                         fit_lpe3_mom[3])
  ad_lpe3_mle <- ad.test(log(Xi),"f.gamma", fit_lpe3_mle[1], fit_lpe3_mle[2], 
                         fit_lpe3_mle[3])
  ad_lpe3_pwm <- ad.test(log(Xi),"f.gamma", fit_lpe3_pwm$para[3],fit_lpe3_pwm$para[2],
                         fit_lpe3_pwm$para[1])

  plogpearson3 <- function(x, xi, beta, alpha){
    return (pgamma(exp(x) - xi, shape = alpha, scale = beta))
  }
  
  ad_lpe3_mom <- ad.test(Xi,"plogpearson3", fit_lpe3_mom[1], fit_lpe3_mom[2], 
                         fit_lpe3_mom[3])
  ad_lpe3_mle <- ad.test(Xi,"plogpearson3", fit_lpe3_mle[3], fit_lpe3_mle[2], 
                         fit_lpe3_mle[1]) 
  ad_lpe3_pwm <- ad.test(Xi,"plgamma3", fit_lpe3_pwm$para[3],fit_lpe3_pwm$para[2],
                         fit_lpe3_pwm$para[1])

  ad_gev_mom <- ad.test(Xi,"pgevd", fit_gev_mom[1], fit_gev_mom[2], 
                        fit_gev_mom[3])
  ad_gev_mle <- ad.test(Xi,"pgevd", fit_gev_mle[1], 
                        fit_gev_mle[2], fit_gev_mle[3])
  ad_gev_pwm <- ad.test(Xi,"pgevd", fit_gev_pwm$para[1], fit_gev_pwm$para[2], 
                        fit_gev_pwm$para[3])
  
  ad_ev1_mom <- ad.test(Xi,"pevd", fit_ev1_mom$parameters[1], 
                        fit_ev1_mom$parameters[2])
  ad_ev1_mle <- ad.test(Xi,"pevd", fit_ev1_mle$parameters[1], 
                        fit_ev1_mle$parameters[2])
  ad_ev1_pwm <- ad.test(Xi,"pevd", fit_ev1_pwm$para[1], fit_ev1_pwm$para[2])
  
  ad_wei_mom <- ad.test(Xi,"pweibull", fit_weibull_mom$parameters[1], 
                        fit_weibull_mom$parameters[2])
  ad_wei_mle <- ad.test(Xi,"pweibull", fit_weibull_mle$parameters[1], 
                        fit_weibull_mle$parameters[2])
  ad_wei_pwm <- ad.test(Xi,"pweibull", fit_weibull_pwm$para[3], 
                        fit_weibull_pwm$para[2])
  
  ad <- c(ad_norm_mom$statistic, 
          ad_norm_mle$statistic,
          ad_norm_pwm$statistic,
          
          ad_ln2_mom$statistic, 
          ad_ln2_mle$statistic,
          ad_ln2_pwm$statistic,
          
          ad_LN3_mom$statistic, 
          ad_LN3_mle$statistic,
          ad_LN3_pwm$statistic,
          
          ad_exp_mom$statistic, 
          ad_exp_mle$statistic,
          ad_exp_pwm$statistic,
          
          ad_gamma_mom$statistic, 
          ad_gamma_mle$statistic,
          ad_gamma_pwm$statistic,
          
          ad_pe3_mom$statistic, 
          ad_pe3_mle$statistic,
          ad_pe3_pwm$statistic,
          
          ad_lpe3_mom$statistic, 
          ad_lpe3_mle$statistic,
          ad_lpe3_pwm$statistic,
          
          ad_gev_mom$statistic, 
          ad_gev_mle$statistic,
          ad_gev_pwm$statistic,
          
          ad_ev1_mom$statistic, 
          ad_ev1_mle$statistic,
          ad_ev1_pwm$statistic,
          
          ad_wei_mom$statistic, 
          ad_wei_mle$statistic,
          ad_wei_pwm$statistic)
  return(ad)
}

ad <- ad_f(Xi)
names(ad) <- NULL
ad <- round(ad, 3)
which.min(ad)


# gev_pwm
p + geom_line(aes(x = T, y = gev_mle, color = "gev_mle" ), size = 2) + 
  ggtitle("Best Fit by AD Test") +
  xlab("Return Period(Years)") + ylab("Flow Rate(m^3/s)") +
  geom_point(size = 2)


#========= MRDs
sheets
data1 <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "ash")
data2 <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "bourne")
data3 <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "belmont")
data4 <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "erwood")
data5 <- read_excel("C:\\Users\\26752\\Desktop\\1.xlsx", sheet = "redbrook")
X1 <- sort(data1$`Flow(m^3/s)`)
X2 <- sort(data2$`Flow(m^3/s)`)
X3 <- sort(data3$`Flow(m^3/s)`)
X4 <- sort(data4$`Flow(m^3/s)`)
X5 <- sort(data5$`Flow(m^3/s)`)


lmrd(samlmu(X1),ylim=c(0,0.4),xlim=c(-0.4,0.6),pch=8)
lms <- lmoms(X2)
points(lms$ratios[3],lms$ratios[4],pch=8)
lms <- lmoms(X3)
points(lms$ratios[3],lms$ratios[4],pch=8)
lms <- lmoms(X4)
points(lms$ratios[3],lms$ratios[4],pch=8)
lms <- lmoms(X5)
points(lms$ratios[3],lms$ratios[4],pch=8)
legend("bottomleft", 
       legend = c("E (Exponential)", "G (Gumbel)", "L (Logistic)", "N (Normal)", "U (Uniform)"),
       pch = 15, cex=0.8)


title("L-moment Ratio Diagram")

#======================= Cross Validation=======================================
# ===========LOOCV=============
  


# for loop
mean_cv <- function(Xi){
  errors <- numeric(N)
  for (i in 1:N) {
    # train and test
    train_data <- Xi[-i]
    test_data <- Xi[i]
    
    # use trian as a model by mean
    predict_val <- mean(train_data)  
    
    # get error
    errors[i] <- (predict_val - test_data)^2
  }
  
  # get mse
  rmse <- sqrt(mean(errors))
  return(rmse)
}

mean_cv(X5)





cv_ev1 <- function(x){
  # Observation
  obs_data <- x
  
  # Prepare vector error for each training
  errors <- numeric(N) 
  
  for (i in 1:N) {
    # cut i_th from obs
    train_data <- obs_data[-i]
    
    # get parameter for fit_ev1 from training set
    fit_ev1_pwm <- lmom2par(lmoms(train_data),type="gum")
    
    # quantile for i_th predict
    p = i/(N + 1)
    
    # get predicted value
    predicted_val <- qevd(p, location = fit_ev1_pwm$para[1], scale = fit_ev1_pwm$para[2])
    
    # calculate error
    errors[i] <- (predicted_val - obs_data[i])^2
  }
  
  # Get RMSE
  rmse <- sqrt(mean(errors))
  return(rmse)
}



cv_ln3 <- function(x){
  # Observation
  obs_data <- x
  
  # Prepare vector error for each training
  errors <- numeric(N) 
  
  for (i in 1:N) {
    # cut i_th from obs
    train_data <- obs_data[-i]
    
    # get parameter for fit_ln3 from training set
    fit_LN3_pwm <-  lmom2par(lmoms(train_data),type="ln3")
    # quantile for i_th predict
    p = i/(N + 1)
    
    # get predicted value
    predicted_val <- qlnorm3(pT, 
                             meanlog = fit_LN3_pwm$para[2], 
                             sdlog = fit_LN3_pwm$para[3],
                             threshold = fit_LN3_pwm$para[1])
    
    # calculate error
    errors[i] <- (predicted_val - obs_data[i])^2
  }
  
  # Get RMSE
  rmse <- sqrt(mean(errors))
  return(rmse)
}


cv_ln2 <- function(x){
  # Observation
  obs_data <- x
  
  # Prepare vector error for each training
  errors <- numeric(N) 
  
  for (i in 1:N) {
    # cut i_th from obs
    train_data <- obs_data[-i]
    
    # get parameter for fit_ln3 from training set
    fit_LN2_pwm <- LN2_pwm(train_data)
    # quantile for i_th predict
    p = i/(N + 1)
    
    # get predicted value
    predicted_val <- qlnorm(pT, meanlog = fit_LN2_pwm$mu_est, sdlog = fit_LN2_pwm$sigma_est)
    
    # calculate error
    errors[i] <- (predicted_val - obs_data[i])^2
  }
  
  # Get RMSE
  rmse <- sqrt(mean(errors))
  return(rmse)
}




