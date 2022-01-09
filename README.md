### Data: 

 - `image1.txt`, `image2.txt`, `image3.txt` (including y coordinate, x coordinate, expert labels, NDAI, SD, CORR, DF, CF, BF, AF and AN). 
 
 - To find specific explanations for each variable, please refer to the paper written by Shi et al. 
(https://sakai.duke.edu/access/content/group/5d6f5214-a10d-46e6-b514-50ce0b5989c0/Projects/Project2/yu2008.pdf)

### Code:

- `Project.rmd` includes all the code for data analysis
- `CVMaster.r` includes the function for Cross Validation part (Detailed explanation for CVMaster is included in the classification models section)
- `Project_Report.pdf` is the final report 

## Reproducibility

### Data Preparation

Before we fit fancy classification models, it's always better to explore the data and check some of the assumptions. After downloading the image data, we plotted three images using AN feature since it's the best angle to reproduce images similar to satellite pictures so that we could have a general sense about the data and corresponding variables. We also plotted images with expert labels to explore patterns, abnormalities, potential classification models for each class. And we found that points are not identically independently distributed since points in the same class tend to cluster in the same region and points contain information about nearby points. So, randomly pick points to train model does not make sense anymore (similar to time series analysis) and we separated images into several blocks to break the dependence issue. In addition, we came up with two ways to separate the data: 1. first combine three images together as the complete dataset (image three images are overlapped with each other since they have the same range for x and y), then separated the combined image into 9 blocks in according to y-axis. 2. separate each image into 9 blocks in according to y-axis one by one, then combine the corresponding blocks from three images as train, validation and test dataset (now we have 3x9 blocks in total compared to 1x9 blocks before). 

After separating the images, we tested the accuracy for trivial classifier by setting predicted label as one single class as our base classification model, and also fitted simple linear regression model for each feature one by one to check the interpretability for each feature and chose three "best" features as NDAI, CORR and AF by looking at R-squared values. Assisted by density plots and expertly labeled images, the results for "best" features are consistent with what we found in the previous section. 

### Classification Models

We dropped the "0" class to turn the problem into binary classification problem and the goal is to classify cloudy (1) points versus clear(-1) points correctly. For binary classification models, we chose logistic regression, LDA, QDA and random forest as our classification models. Then we checked assumptions for each of them-- for logistic regression, we used `corr` and graphs using log odds as y-axis and feature values as x axis to check corresponding assumptions, for LDA and QDA, linearity multivariate normality test in the `QuantPsyc` library was used to check Gaussian assumption, and also used correlation matrix distance formula to check the common covariance matrix assumption for LDA specifically. Since there is no strong assumption for random forest, we didn't test any assumptions for it. 

Then we used CVMaster function to train each classification model one by one with cross validation. Specifically, CVmaster takes a classifier, training features, training labels, number of folds, and a loss function as inputs, and outputs the K-fold CV loss on the training set. Since our data is not independent with each other, we need to divide them into blocks to eliminate dependency to some extent. In this case, the training features should include the y coordinate information. The function first examine whether the number of blocks (B) is larger than K, if not, throw an error to warn the user to decrease K. Then it divides the data into B blocks according to y coordinate, and choose training blocks and validation blocks randomly to get training data and validation data for each fold. Within each fold, it uses training dataset to train the classifier, and uses the trained model to predict labels on validation dataset. Then it calculates the loss using predicted labels and true labels on validation dataset. Finally it returns a vector of loss across K folds as the output.
 
### Diagnostics 

After training the model, we got accuracy table for each method in two different separating ways, and from the table, we found that random forest has the highest accuracy and fold 1 has the worst performance in accuracy. Then we plotted ROC curves to show the trade-off between FPR and TPR and found that ROC curve for random forest is the closet one to the best theoretical ROC curve, which is consistent with what we found through accuracy table. In addition, we chose the cutoff with highest TPR as the optimal cutoff since we care more about classifying cloudy area (TPR) correctly and marked them in the curve for each method. Some other diagnostics were used to assess each model: AUC, precision, recall and F1 score. By plotting AUC for each method, we learned that random forest has the best performance and is the best classification model for the data. From the table including other statistics, we could determine best model based on different emphasis or goal of the study (value more on TPR or FPR or both). What's more, predicted labeled images were plotted to have better visualization for the inaccuracies of each method, and from the plot, we could see that random forest has the smallest wrongly predicted regions, which indicates it's the best model. Through cross validation and the plot of OOB (tune parameter), we found that mtry = 3 is the optimal parameter for random forest model. 

For our best classification model-- random forest, we plotted importance feature figure to check the importance of each variable used for predicting labels and the results are also consistent with what we found in the first section. To check convergence, error rate plot vs mtry plot was used and the trend indicates the convergence of the error rate (decrease to 0). And to explore more about high misclassification rate in specific region and range of feature values, points in fold 1 were pull out to check. More imbalanced data in fold 1 as well as different range of feature values might lead to low accuracy specifically for fold 1. 

In general, random forest with mtry = 3 is the best classification model among all the models we tried above, followed by QDA, and the performance for LDA and logistic regression is pretty similar. 
