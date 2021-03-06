# TA: Leslie Huang
# Course: Text as Data
# Date: 2/13/2020
# Lab adapted from: Kevin Munger, Patrick Chester Leslie Huang, Pedro L. Rodriguez

## Set up Quanteda 

# Clear Global Environment
rm(list = ls())

# Libraries
library(dplyr)
library(quanteda)
library(quanteda.corpora)

# sophistication: https://github.com/kbenoit/sophistication
# gutenbergr: https://cran.r-project.org/web/packages/gutenbergr/index.html, 
# http://www.gutenberg.org/wiki/Main_Page
# stylest: https://leslie-huang.github.io/stylest/
# corpus: https://cran.r-project.org/web/packages/corpus/

#-----------------------------
# 1 NON-ENGLISH TEXTS
#-----------------------------

# 1.1 Non-English stopwords

stopwords(language = "spanish")

stopwords(language = "german")

stopwords(language = "zh", source = "misc")

# 1.2 Text encoding

# What is text encoding?
# How do you figure out what kind you have (e.g. scraped text from the Internet)?
# What kind of encoding can R and/or quanteda handle?

# 1.3 Some types of text encoding
# character encoding is a set of mappings between the bytes in the computer and the characters in the character set.
# UTF-8
# ASCII (subset of UTF-8)
# Latin-1

# UTF-8 represents characters from European languages (English, Spanish, German, French, etc) and some characters from Chinese/Japanese/Korean, plus emojis.

# Note: Text obtained from Internet sources can be messy. Issues can especially arise when you are working with texts from multiple sources and you end up with a mixture of encodings. This can cause the encoding to be detected incorrectly when you read in the text.

# 1.4 What encoding do you have?

# You can check with this function in base R
validUTF8("This is a sentence")

# You can use the package utf8 by Patrick Perry
# Read about it here: https://cran.r-project.org/web/packages/utf8/index.html
# install.packages("utf8")
library("utf8")

as_utf8("\xF0\x9F\x98\x8D")
print("\xF0\x9F\x98\x8D") # There are issues with base R's print() function for Unicode
# any guesses what this is?
utf8_print("\xF0\x9F\x98\x8D")
# emojis unicodes: https://apps.timwhitlock.info/emoji/tables/unicode

# 1.5 What if you get a weird character and you're not sure?

# install.packages("stringi")
library("stringi")

# Use the encoding guesser to guess what this character is
stri_enc_detect("0x00E3")

# It's only a guess!

# What's ISO-8859-1?
# This is another name for the Latin-1 encoding. 

# 1.6 How do you convert encodings?
test_str <- "São Paulo"
validUTF8(test_str)
converted_str <- iconv("São Paulo", from = "UTF-8", to = "latin1")

converted_str
validUTF8(converted_str)

# Looks the same right?

charToRaw(converted_str) # Latin-1 encoding

charToRaw(test_str) # UTF-8 encoding

# But what about here?
iconv("ã", from = "UTF-8", to = "ASCII")

# In most cases, your text will probably already be in UTF-8. 
# In most cases, you want to convert your text to UTF-8 (with the possible exception of languages that do not use the Latin alphabet)

# The authors of quanteda have also written a package called readtext() that can also deal with encodings in text corpora!

#-----------------------------
# 2 HEAP'S LAW
#-----------------------------
# Token-type relationship in corpus
# How might pre-processing affect this relationship? 
# Think about reducing the dimensionality of the problem.

#     M = kT^b

# M = vocab size (num of types)
# T = number of tokens

# k, b are constants
# 30 <= k <= 100
# 0.4 <= b <= 0.6

# 2.1 Example using data from the corpus of inaugural speeches
tokens <- tokens(data_corpus_inaugural, remove_punct = TRUE) 
num_tokens <- sum(lengths(tokens))

inaug_dfm <- dfm(data_corpus_inaugural)

M <- nfeat(inaug_dfm)  # number of features = number of types

# Let's check using parameter values from MRS Ch. 5 for a corpus with more than 100,000 tokens

k <- 54
b <- 0.49

k * (num_tokens)^b

M

# Let's think about why (what types of texts are these?)

# New parameters

k <- 44
b <- 0.455

k * (num_tokens)^b

M

# You can solve mathematically for k and b or fit a model to find k and b -- relationship between log(collection size) and log(vocab size) is linear

#-----------------------------
# 3 ZIPF'S LAW
#-----------------------------
# Term frequency in corpus and rank

# x-axis: log of ranks 1 through 100
# y-axis log of frequency of top 100 terms from the DFM

plot(log10(1:100), log10(topfeatures(inaug_dfm, 100)),
     xlab = "log10(rank)", ylab = "log10(frequency)", main = "Top 100 Words in U.S. Presidential Inaugural Speech Corpus")

# Fits a linear regression to check if slope is approx -1.0
regression <- lm(log10(topfeatures(inaug_dfm, 100)) ~ log10(1:100))

# Adds the fitted line from regression to the plot
abline(regression, col = "red")

# Returns the 95% confidence intervals for the regression coefficients
confint(regression)

# Provides R-squared, F-test, and cofficient estimates from regression
summary(regression)

## Stopwords: do they affect Zipf's law?

inaug_dfm_nostop <- dfm(data_corpus_inaugural, remove=stopwords("english"))

plot(log10(1:100), log10(topfeatures(inaug_dfm_nostop, 100)),
     xlab = "log10(rank)", ylab = "log10(frequency)", main = "Top 100 Words in U.S. Presidential Inaugural Speech Corpus (w/o stopwords)")

# Regression to check if slope is approx -1.0
regression <- lm(log10(topfeatures(inaug_dfm_nostop, 100)) ~ log10(1:100))
abline(regression, col = "red")
confint(regression)
summary(regression)

# Zipf's law as a feature selection tool (e.g. http://www.jmlr.org/papers/volume3/forman03a/forman03a_full.pdf)

plot(1:100, topfeatures(inaug_dfm, 100),
     xlab = "rank", ylab = "frequency", main = "Top 100 Words in U.S. Presidential Inaugural Speech Corpus")

plot(1:100, topfeatures(inaug_dfm_nostop, 100),
     xlab = "rank", ylab = "frequency", main = "Top 100 Words in U.S. Presidential Inaugural Speech Corpus (w/o stopwords)")

#-----------------------------
# 5 MEASURING SIMILARITY
#-----------------------------
# This helps illustrate the value of the vector representation

# 5.1 Cosine similarity--take the dot product of two vectors
# cos = x*y/|x||y|
calculate_cosine_similarity <- function(vec1, vec2) { 
  nominator <- vec1 %*% vec2  # %*% specifies dot product rather than entry by entry multiplication (we could also do: sum(x * y))
  denominator <- sqrt(vec1 %*% vec1)*sqrt(vec2 %*% vec2)
  return(nominator/denominator)
}

# example 1
x <- c(1, 2, 3)
y <- c(1, 2, 3)

# what should we get?
calculate_cosine_similarity(x, y)

# example 2
a <- c(1, 2, 3)
b <- c(-1, -2, -3)

# what should we get?
calculate_cosine_similarity(a, b)

# Let's do it with texts
obama_text <- texts(corpus_subset(data_corpus_inaugural, President == "Obama"))
lincoln_text <- texts(corpus_subset(data_corpus_inaugural, President == "Lincoln"))

# Make a dfm of these two
obama_lincoln_dfm <- dfm(c(obama_text, lincoln_text), remove = stopwords("english"), stem = TRUE)

# Calculate similarity
similarity_obama_lincoln_with_preprocessing <- textstat_simil(obama_lincoln_dfm, margin = "documents", method = "cosine")
as.matrix(similarity_obama_lincoln_with_preprocessing)

# 5.2 Let's see how stopwords/stemming affect similarity

obama_lincoln_no_preprocessing <- dfm(c(obama_text, lincoln_text))

# Calculate similarity

similarity_obama_lincoln_with_no_preprocessing <- textstat_simil(obama_lincoln_no_preprocessing, margin = "documents", method = "cosine")

as.matrix(similarity_obama_lincoln_with_no_preprocessing)

# Make a dfm of a several documents

several_inaug_dfm <- dfm(corpus_subset(data_corpus_inaugural , Year > 1980), remove = stopwords("english"), stem = TRUE)

# Other options available: Manhattan distance, correlation, etc.
?textstat_simil

#-----------------------------
# 6 STYLE
#-----------------------------

# 6.1 data collection (to be used in HW1)
rm(list = ls())
# 6.2 Project Gutenberg: http://www.gutenberg.org/wiki/Main_Page
# collection of (machine readable) novels and other texts + they have an R package!
#install.packages("gutenbergr")
# for more info refer to: https://cran.r-project.org/web/packages/gutenbergr/vignettes/intro.html
library(gutenbergr)
library(dplyr)
gutenberg_works()

# what do they have by Jane Austen?
gutenberg_works() %>% filter(author == "Austen, Jane")

# download "Emma"
emma <- gutenberg_download(gutenberg_id = 158)
#emma <- gutenberg_download(jane_austen$gutenberg_id[jane_austen$title == "Emma"], meta_fields = "title")  # add other meta information

# 6.3 stylest package: estimate speaker (author) style distinctiveness (vis-a-vis other authors)
# see https://leslie-huang.github.io/stylest/

# source for this code: package vignette
library(stylest)

# data included in package
data(novels_excerpts)

# author list
unique(novels_excerpts$author)

# note how the data is organized
str(novels_excerpts)

# (1) select most informative (discriminative) features (subsets vocab by frequency percentile)
filter <- corpus::text_filter(drop_punct = TRUE, drop_number = TRUE)  # pre-processing choices
set.seed(1984L)  # why set seed?
vocab_custom <- stylest_select_vocab(novels_excerpts$text, novels_excerpts$author,  # fits n-fold cross-validation
                                     filter = filter, smooth = 1, nfold = 5,
                                     cutoff_pcts = c(25, 50, 75, 99))

vocab_custom$cutoff_pct_best  # percentile with best prediction rate
vocab_custom$miss_pct  # rate of incorrectly predicted speakers of held-out texts

# (2) subset features
vocab_subset <- stylest_terms(novels_excerpts$text, novels_excerpts$author, vocab_custom$cutoff_pct_best , filter = filter) # USE SAME FILTER

# (3) fit model with "optimal" percentile threshold (i.e. feature subset)
style_model <- stylest_fit(novels_excerpts$text, novels_excerpts$author, terms = vocab_subset, filter = filter)

# explore output
head(stylest_term_influence(style_model, novels_excerpts$text, novels_excerpts$author))  # influential terms

authors <- unique(novels_excerpts$author)
term_usage <- style_model$rate
lapply(authors, function(x) head(term_usage[x,][order(-term_usage[x,])])) %>% setNames(authors)

# odds for known texts
odds <- stylest_odds(style_model, novels_excerpts$text, novels_excerpts$author)
odds

# (4) predict speaker of a new text
new_text <- emma$text[30:75] %>% paste(., collapse = "") 
pred <- stylest_predict(style_model, new_text)
pred$predicted
pred$log_probs

#-----------------------------
# 8 SOPHISTICATION
#-----------------------------
# motivation: flexibly measure the "sophistication" (ease of understanding) of political communication 
# see paper: https://www.nyu.edu/projects/spirling/documents/BMS_complex.pdf
#install.packages("sophistication")
# HINT FOR YOUR HW!!! see vignette: https://github.com/kbenoit/sophistication
# key insight: use crowdsourcing
# devtools::install_github("kbenoit/sophistication")
library(sophistication)

# Example taken from vignette
# make the snipepts of one sentence, between 100-250 chars in length
data(data_corpus_sotu, package = "quanteda.corpora")
snippetData <- snippets_make(data_corpus_sotu, nsentence = 1, minchar = 150, maxchar = 250)
# clean up the snippets
snippetData <- snippets_clean(snippetData)

testData <- snippetData[sample(1:nrow(snippetData), 5), ]
(snippetPairsMST <- pairs_regular_make(testData))

#-----------------------------
# 9 COLLOCATIONS (again)
#-----------------------------
# bigrams

trump_2018_text <- corpus_subset(data_corpus_sotu, President == "Trump")[2]
head(textstat_collocations(trump_2018_text)) # see documentation
textstat_collocations(trump_2018_text) %>% arrange(-lambda) %>% slice(1:5)

# lambda is the n-way interaction term from a saturated log-linear model
# z is from the Wald test z-stat

# trigrams
?textstat_collocations
head(textstat_collocations(trump_2018_text, size = 3))
