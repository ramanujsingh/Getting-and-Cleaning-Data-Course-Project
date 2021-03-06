---
title: "run_analysis"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

Preprocessing
-------------

First, we will load package.


```{r}
require("dplyr")
require("reshape2")
require("data.table")

```

Set path.


```{r}
path <- getwd()
path
```

```
## [1] "E:/Research/Statistics/Data_cleaning/"
```



Get the data
------------

Unzip the file.


```{r}

exe <- file.path("C:", "Program Files", "winrar", "winrar.exe")
data_path <- file.path(".", "getdata-projectfiles-UCI HAR Dataset.zip")
command <- paste(paste0("\"", exe, "\""), " x ", paste0("\"", data_path, "\"") )

system(command)
```


After uncompression, Folder `UCI HAR Dataset` will be created. Create data_dir variable for this directory. List this directory recursively.


```r
data_dir <- file.path(".", "UCI HAR Dataset")

dir(path = data_dir, recursive = TRUE)

```

```
# [1] "activity_labels.txt"                          "features.txt"                                
# [3] "features_info.txt"                            "README.txt"                                  
# [5] "test/Inertial Signals/body_acc_x_test.txt"    "test/Inertial Signals/body_acc_y_test.txt"   
# [7] "test/Inertial Signals/body_acc_z_test.txt"    "test/Inertial Signals/body_gyro_x_test.txt"  
# [9] "test/Inertial Signals/body_gyro_y_test.txt"   "test/Inertial Signals/body_gyro_z_test.txt"  
# [11] "test/Inertial Signals/total_acc_x_test.txt"   "test/Inertial Signals/total_acc_y_test.txt"  
# [13] "test/Inertial Signals/total_acc_z_test.txt"   "test/subject_test.txt"                       
# [15] "test/X_test.txt"                              "test/y_test.txt"                             
# [17] "train/Inertial Signals/body_acc_x_train.txt"  "train/Inertial Signals/body_acc_y_train.txt" 
# [19] "train/Inertial Signals/body_acc_z_train.txt"  "train/Inertial Signals/body_gyro_x_train.txt"
# [21] "train/Inertial Signals/body_gyro_y_train.txt" "train/Inertial Signals/body_gyro_z_train.txt"
# [23] "train/Inertial Signals/total_acc_x_train.txt" "train/Inertial Signals/total_acc_y_train.txt"
# [25] "train/Inertial Signals/total_acc_z_train.txt" "train/subject_train.txt"                     
# [27] "train/X_train.txt"                            "train/y_train.txt" 
```

#Merge Training and Test set to create a new set

Load test data
```{r}

xtest <- read.table(file.path(data_dir, "test", "X_test.txt"))
head(xtest)
str(xtest)
summary(xtest)

```

```{r}
ytest <- read.table(file.path(data_dir, "test", "y_test.txt"))
head(ytest)
str(ytest)
summary(ytest)

```

```{r}
subjecttest <- read.table(file.path(data_dir, "test", "subject_test.txt"))
head(subjecttest)
str(subjecttest)
summary(subjecttest)

```

Validate number of observation is same

```{r}
nrow(xtest) == nrow(ytest)
nrow(xtest) == nrow(subjecttest)
```

Merge X test and Subject Data set.

```{r}
testset = xtest
testset = mutate(testset, subject = as.integer(subjecttest$V1))
head(testset)
str(testset)
summary(testset)
```

Merge Y test into Test set.
```{r}
test.activityf <- factor(ytest$V1, levels=activity.labels$V1, labels=activity.labels$V2)
testset <- mutate(testset, activity = test.activityf)
head(testset)
str(testset)
summary(testset)

```

Do similar for Training Data Set.

```{r}
xtrain <- read.table(file.path(data_dir, "train", "X_train.txt"))
ytrain <- read.table(file.path(data_dir, "train", "y_train.txt"))
subjecttrain <- read.table(file.path(data_dir, "train", "subject_train.txt"))

trainset <- mutate(xtrain, subject = as.integer(subjecttrain$V1))
trainset <- mutate(trainset, activity = as.integer(ytrain$V1))
head(trainset)
str(trainset)
summary(trainset)
```

Merge Training and Test Data set.

```{r}
data = rbind(testset, trainset)
head(data)
str(data)
summary(data)
```

# Get mean and standard deviation for each measurement. 

Read the `features.txt` file. This tells which variables in `data` are measurements for the mean and standard deviation.

```{r}
dtFeatures <- read.table(file.path(data_dir, "features.txt"))
dtFeatures <- mutate(dtFeatures, varname=paste0("V", V1))
dtFeatures

```

Subset only measurements for the mean and standard deviation.

```{r}
dtFeatures <- filter(dtFeatures, grepl('(mean|std)', V2, ignore.case=T) & !grepl('^angle\\(', V2))
dtFeatures
vars = c(dtFeatures$varname, c("subject", "activity"))
vars
data2 = select(data, one_of(vars))
names(data2)
summary(data2)
```

# Use descriptive activity names

Read `activity_labels.txt` file. This will be used to add descriptive names to the activities.

```{r}
dtActivityNames <- read.table(file.path(data_dir, "activity_labels.txt"))
dtActivityNames
activityf = factor(data2$activity, levels=dtActivityNames$V1, labels=dtActivityNames$V2)
names(activityf)
summary(activityf)
```

Add activity column to data set

```{r}
data3 = mutate(data2, activity = activityf)
summary(data3)

```

Add descriptive names

```{r}
oldnames = dtFeatures$varname
oldnames

newnames = as.character(dtFeatures$V2)
newnames
setnames(data3, old=oldnames, new=newnames)
names(data3)
```

# Create tidy data set

Group by Subject and Activity
```{r}
data.melt = melt(data3, id=c("subject", "activity"), measure.vars=newnames)
mean.data = dcast(data.melt, subject + activity ~ variable, mean)
oldnames = names(mean.data)[3:length(names(mean.data))]
newnames = as.character(sapply(oldnames, function(n) paste0("subject-activity-mean-", n)))
setnames(mean.data, old=oldnames, new=newnames)
head(mean.data)

```

Write tidy data set

```{r}
write.table(mean.data, file="HAR-subject-activity-mean.txt", row.name=FALSE)

```


Make codebook.


```r
knit("run_analysis.Rmd", output = "codebook.md", encoding = "ISO8859-1", quiet = TRUE)
```

```r
markdownToHTML("codebook.md", "codebook.html")
```
