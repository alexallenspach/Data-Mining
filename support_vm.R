support_vm <- function(training_path, test_path) {
  
  # First install all libraries that will be required for this specific function - simply uncomment below line
  #install.packages(c("sentimentr", "tm", "SnowballC", "e1071", "tictoc", "readr"))
  
  # Load all libraries required to run this function
  library(tictoc)
  library(readr)
  library(sentimentr)
  library(tm)
  library(SnowballC)
  library(e1071)
  
  tic()
  
  training_path <- read_csv(training_path)
  test_path <- read_csv(test_path)
  
  sentimentTrain = sentiment_by(training_path$text)
  sentimentTest = sentiment_by(test_path$text)
  
  # *** TRAIN ***
  training_path$Avg = sentimentTrain$ave_sentiment
  
  # dependent variable
  training_path$Negative <- as.factor(training_path$Avg <= 0)
  table(training_path$Negative)
  
  # Clean Training Corpus
  corpusTrain <- Corpus(VectorSource(training_path$text))
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, tolower) 
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, removePunctuation)
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, removeNumbers)
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, removeWords, c(stopwords("english")))
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, stemDocument)
  #inspect(corpusTrain[1])
  
  corpusTrain = tm_map(corpusTrain, stripWhitespace)
  #inspect(corpusTrain[1])
  
  
  # *** TEST ***
  test_path$Avg = sentimentTest$ave_sentiment
  
  # dependent variable
  test_path$Negative <- as.factor(test_path$Avg <= 0)
  #table(test_path$Negative)
  
  # Clean Training Corpus
  corpusTest <- Corpus(VectorSource(test_path$text))
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, tolower) 
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, removePunctuation)
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, removeNumbers)
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, removeWords, c(stopwords("english")))
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, stemDocument)
  #inspect(corpusTest[1])
  
  corpusTest = tm_map(corpusTest, stripWhitespace)
  #inspect(corpusTest[1])
  
  # Document Term Matrices
  frequencyTrain = DocumentTermMatrix(corpusTrain)
  frequencyTest = DocumentTermMatrix(corpusTest)
  frequencyTrain
  frequencyTest
  
  # You can see data is very sparse, which means there is many zeros in the matrix
  #inspect(frequencyTrain[800:805,505:515])
  #inspect(frequencyTest[800:805,505:515])
  
  # Look at what the most popular terms are
  # More terms means more independent variables which means it will take longer to build models
  #findFreqTerms(frequencyTrain, lowfreq = 500)
  #findFreqTerms(frequencyTest, lowfreq = 500)
  
  # So remove terms that do not appear very often
  # 2nd arguemnt is threshold (Ex: 0.98 means only keep terms that appear 2% or more in the documents)
  # Change spare threshold to determine feature size (0.97 = 440, 0.95 = 213)
  sparseTrain <- removeSparseTerms(frequencyTrain, 0.95)
  sparseTest <- removeSparseTerms(frequencyTest, 0.95)
  sparseTrain
  sparseTest
  
  # convert sparse matrix into a data matrix that will be able to use for predictive models
  sparseTrainMatrix = as.matrix(sparseTrain)
  sparseTestMatrix = as.matrix(sparseTest)
  
  # Make the testing dataset and training dataset be of identical length
  sparseTrainDF = as.data.frame(sparseTrainMatrix[,intersect(colnames(sparseTrainMatrix), colnames(sparseTestMatrix))])
  sparseTestDF = as.data.frame(sparseTestMatrix[,intersect(colnames(sparseTestMatrix), colnames(sparseTrainMatrix))])
  
  # Since our struggles with variable names that start with a number and probably some words that start with a number, run make names to make sure 
  # variable names are appropriate before building any predictive models
  colnames(sparseTrainDF) = make.names(colnames(sparseTrainDF))
  colnames(sparseTestDF) = make.names(colnames(sparseTestDF))
  
  # Add dependent variable to dataset
  sparseTrainDF$Negative = training_path$Negative
  sparseTestDF$Negative = test_path$Negative
  
  # SVM Model
  svmModel = svm(Negative~., data = sparseTrainDF)
  predictSVM = predict(svmModel, newdata = sparseTestDF)
  
  ## function to compute accuracy
  accuracy <- function(y, ypred){
    tab <- table(y, ypred)
    return(sum(diag(tab))/sum(tab))
  }
  # function to compute precision
  precision <- function(y, ypred){
    tab <- table(y, ypred)
    return((tab[1,1])/(tab[1,1]+tab[1,2]))
  }
  # function to compute recall
  recall <- function(y, ypred){
    tab <- table(y, ypred)
    return(tab[1,1]/(tab[2,1]+tab[1,1]))
  }
  
  # performance metrics - SVM
  accuracySVM = accuracy(sparseTestDF$Negative, predictSVM)
  missclassification = 1 - accuracySVM
  precision = precision(sparseTestDF$Negative, predictSVM)
  recallSVM = recall(sparseTestDF$Negative, predictSVM)
  confMatrix = table(sparseTestDF$Negative, predictSVM)
  
  # confusion matrix - SVM
  print(confMatrix)
  print(paste("Accuracy of SVM Model:", accuracySVM))
  print(paste("Missclassification for SVM:", missclassification))
  print(paste("Recall for SVM Model:", recallSVM))
  toc()
}


# Function Call - Make sure to change path to location on your computer!
support_vm("A:\\Alex\\Documents\\UCCS 2020\\Fall 2020\\Ind Study - Machine Learning\\Project 2\\20_newsgroups_Train.csv", "A:\\Alex\\Documents\\UCCS 2020\\Fall 2020\\Ind Study - Machine Learning\\Project 2\\20_newsgroups_Test.csv")



