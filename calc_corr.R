rm(list = ls())
library("RMySQL")
library("reshape2")
nas <- read.csv(file = 'M6-NasdaqReturns.csv')
mat.nas <- data.matrix(nas[,4:123])
avgreturn <-  apply(mat.nas, 1, mean)
symbols <- nas$StockSymbol
avgreturn <- as.data.frame(cbind(symbols, avgreturn))
avgreturn[,1] <- nas$StockSymbol
rownames(mat.nas) <- nas$StockSymbol
mat.nas <- t(mat.nas)
cov_mat <- cov(mat.nas)
smelt <- melt(cov_mat)
db <- RMySQL:: dbConnect(drv = RMySQL::MySQL(), dbname = "nasdaq", username = "root", password = "root")
beginsql <-  sprintf("insert into cov (stock1, stock2, covariance) values")
sql <- c()
for (i in 1:nrow(smelt)) {
  sql[i] <- sprintf("('%s', '%s', %s), " , 
                    smelt[i,1], smelt[i,2], smelt[i,3])
  if (i %% 1000 == 0 | i == nrow(smelt)) {
    # dump batch
    sql[i] <- sprintf("('%s', '%s', %s);" , 
                      smelt[i,1], smelt[i,2], smelt[i,3],2)
    if(i == 1000) {
      dbSendQuery(db, paste(beginsql, paste(sql, collapse = '')))
    } else {
      j <- lastDump + 1
      dbSendQuery(db, paste(beginsql, paste(sql[j:i], collapse = '')))
    }
    lastDump <- i 
  }
}
beginsql2 <- sprintf("insert into r (stock, meanReturn) values")
sql2 <- c()
for (i in 1:nrow(avgreturn)) {
  sql2[i] <- sprintf("('%s', %s), " , 
                     avgreturn[i,1], avgreturn[i,2])
  if(i == nrow(avgreturn)) {
    sql2[i] <- sprintf("('%s', %s); " , 
                       avgreturn[i,1], avgreturn[i,2])
    dbSendQuery(db, paste(beginsql2, paste(sql2, collapse = '')))
  }
}
