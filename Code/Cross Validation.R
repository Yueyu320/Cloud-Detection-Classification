CVmaster = function(classifier, features, label, K, loss = function(pred, true){mean(pred==true)}, mtry=3, thresh = 0.5){
  if(!'y' %in% colnames(features))
    stop("The features need to include y coordinate in order to divide blocks!")
  # number of blocks
  B = 9
  # K should be smaller than number of blocks
  if(K > B)
    stop(paste0("The number of folds need to be smaller than the number of blocks: ",B,"!"))
  # blocked (according to y) dataset
  features$label = as.factor(label)
  cutoff = seq(min(features$y), max(features$y), length.out = B+1)
  cutoff[1] = cutoff[1] - 1
  blocks = lapply(1:B, function(i){
    df = features[features$y<=cutoff[i+1] & features$y>cutoff[i], !names(features)%in%c('x','y','expert')]
    df$block = i
    df
  })
  data_bloc = do.call("rbind", blocks)
  # create CV folds
  val_index = createFolds(1:length(blocks), k = K)
  # calculate CV loss for Logistic regression, LDA, QDA and random forest
  CV_loss = c()
  
  # Logistic regression
  if(classifier == "Logistic Regression"){
    if(any(levels(features$label) %in% c("0", "1")))
      stop("The label should only be 0 or 1 for logsitic regression!")
    for(i in 1:K){
      valid = data_bloc %>% 
        filter(block %in% val_index[[i]]) %>% 
        select(-block)
      train = data_bloc %>% 
        filter(!block %in% val_index[[i]]) %>% 
        select(-block)
      log_reg = glm(label ~ ., data = train, family = "binomial")
      prob = predict(log_reg, newdata = valid, type = "response")
      pred = as.factor(as.integer(prob > thresh))
      CV_loss = c(CV_loss, loss(pred, valid$label))
    }
  }
  # LDA
  else if(classifier == "LDA"){
    for(i in 1:K){
      valid = data_bloc %>% 
        filter(block %in% val_index[[i]]) %>% 
        select(-block)
      train = data_bloc %>% 
        filter(!block %in% val_index[[i]]) %>% 
        select(-block)
      lda =  MASS::lda(label ~ ., data = train)
      pred = predict(lda, newdata = valid, type = "class")$class
      CV_loss = c(CV_loss, loss(pred, valid$label))
    }
  }
  
  # QDA
  else if(classifier == "QDA"){
    for(i in 1:K){
      valid = data_bloc %>% 
        filter(block %in% val_index[[i]]) %>% 
        select(-block)
      train = data_bloc %>% 
        filter(!block %in% val_index[[i]]) %>% 
        select(-block)
      qda =  MASS::qda(label ~ ., data = train)
      pred = predict(qda, newdata = valid, type = "class")$class
      CV_loss = c(CV_loss, loss(pred, valid$label))
    }
  }
  # random forest
  else if(classifier == "Random Forest"){
    for(i in 1:K){
      valid = data_bloc %>% 
        filter(block %in% val_index[[i]]) %>% 
        select(-block)
      train = data_bloc %>% 
        filter(!block %in% val_index[[i]]) %>% 
        select(-block)
      rf = randomForest(label ~., data = train, mtry = mtry, importance = TRUE)
      pred = predict(rf, newdata = valid)
      CV_loss = c(CV_loss, loss(pred, valid$label))
    }
  }
  else
    stop("The classifier is not applicable to CVmaster, choose one of 'Logistic Regression', 'LDA', 'QDA', 'Random Forest'!")
  
  return(CV_loss)
}