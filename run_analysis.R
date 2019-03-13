# PART 1 CREATING TIDY DATA SET

# <downloading and unzipping>

URL <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
if (!file.exists("./data")) {
        dir.create("./data")
}
if (!(file.exists("./data/getdata_projectfiles_UCI HAR Dataset.zip"))) {
        download.file(URL, "./data/getdata_projectfiles_UCI HAR Dataset.zip", mode = "wb")
}
if (!(file.exists("./data/UCI HAR Dataset"))) {
        unzip("./data/getdata_projectfiles_UCI HAR Dataset.zip", exdir = "./data")
}

# </downloading and unzipping>

# <loading packages>

if (!("dplyr" %in% installed.packages())) {
        install.packages("dplyr")
}
library("dplyr")
if (!("tidyr" %in% installed.packages())) {
        install.packages("tidyr")
}
library("tidyr")
if (!("readr" %in% installed.packages())) {
        install.packages("readr")
}
library("readr")


# </loading packages>

# <reading>

features <- read.table("./data/UCI HAR Dataset/features.txt", quote="\"", stringsAsFactors = FALSE)

# test dataset

subject_test <- read.csv("./data/UCI HAR Dataset/test/subject_test.txt", header = FALSE)
names(subject_test) <- "subject"
y_test <- read.csv("./data/UCI HAR Dataset/test/y_test.txt", header = FALSE)
names(y_test) <- "activity"
x_test <- read.table("./data/UCI HAR Dataset/test/X_test.txt", quote="\"")
names(x_test) <- features[[2]]

test_data <- cbind(subject_test, y_test, x_test[, grepl(("mean|std"), names(x_test))])

rm(subject_test, y_test, x_test)

# Adding datatype column before merging with training dataset:

test_data <- cbind(test_data, set = rep("test", nrow(test_data)))

# traing dataset

subject_train <- read.csv("./data/UCI HAR Dataset/train/subject_train.txt", header = FALSE)
names(subject_train) <- "subject"
y_train <- read.csv("./data/UCI HAR Dataset/train/y_train.txt", header = FALSE)
names(y_train) <- "activity"
x_train <- read.table("./data/UCI HAR Dataset/train/X_train.txt", quote="\"")
names(x_train) <- features[[2]]

training_data <- cbind(subject_train, y_train, x_train[, grepl(("mean|std"), names(x_train))])

rm(subject_train, y_train, x_train)

# Adding datatype column before merging with training dataset:

training_data <- cbind(training_data, set = rep("training", nrow(training_data)))

# </reading>

# <merging>

merged_data <- rbind(test_data, training_data)

rm(test_data, training_data)

# </merging>

# <tidying data>

columnnames <- names(merged_data)
columnnames <- gsub("-|\\()", "", columnnames)
names(merged_data) <- columnnames



## A loop is coded in order add a counter of the number of observations that every subject returns for each activity.
## First we need to arrange the data as the original dataset is not ordered by activity of each subject:

merged_data <- arrange(merged_data, subject, activity)
rep <- vector(mode = "numeric", length = nrow(merged_data))
for (i in 1:nrow(merged_data)) {
        indx <- i-1
        if(indx == 0) {
                counter <- 1
        }
        if(indx != 0) {
                if (merged_data[i, 1] == merged_data[indx, 1] & merged_data[i, 2] == merged_data[indx, 2]) {
                        counter <- counter + 1
                }else{
                        counter <- 1
                }
        }
        rep[i] <- counter
}

merged_data <- mutate(merged_data, observation = rep)

## Changing activity numbers by labels:
##      1- Elimminate [1-9] numbers, so only characters remain.
##      2- Elimminate _ between words like in "Walking_Upstairs" ----> "Walking Upstairs"

activity_labels <- read.csv("./data/UCI HAR Dataset/activity_labels.txt", header = FALSE, stringsAsFactors = FALSE)
activity_labels <- sub("[1-9] ", "", activity_labels$V1)
activity_labels <- gsub("_", " ", activity_labels)
merged_data <- mutate(merged_data, activity = activity_labels[activity])

##Gathering columns and clasifying them between mean and standarddeviation measure types:

experimental <- gather(merged_data, feature, measure, -subject, -activity, -set, -observation)

## Identify rows where theres's either a mean or a std value and add a new column to diferentiate them:

means_vect <- grepl("mean", experimental$feature)                       
means_vect <- gsub("TRUE", "mean", means_vect)
means_vect <- gsub("FALSE", "standarddeviation", means_vect)
experimental <- mutate(experimental, measuretype = means_vect)

## Cleaning "mean" and "std" from feature's column values.
experimental$feature <- gsub("mean|std", "", experimental$feature)

# </tidying data>
tidy_data <- experimental
rm(experimental, features, merged_data, activity_labels, columnnames, counter, i, indx, means_vect, rep, URL)

# PART 2: SUMARISING DATA

avg_data <- tidy_data %>% 
        group_by(set, subject, activity, feature, measuretype) %>% 
        summarise(avg = mean(measure))
View(avg_data)

# Part 3: Writing data set

write.table(avg_data, "./data/course_project_tidy_data_set.txt", row.names = FALSE )
