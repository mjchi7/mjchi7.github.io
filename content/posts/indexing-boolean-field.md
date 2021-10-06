---
title: "Indexing Boolean Field"
date: 2021-09-29T20:33:45+08:00
draft: true
subtitle: "Does it help to index boolean field?"
---
## Indexing a Boolean Field
So in one of the discussion session with my fellow colleagues, we were talking about the topic of indexing in database. Then, someone asked would it help if we index a boolean field? My [system 1](https://suebehaviouraldesign.com/kahneman-fast-slow-thinking/) kicked in immediately and I said "No, it wouldn't". My reasoning is that for an indexing to be effective on a field, the field has to be high in cardinality score. Since a boolean field can only be true or false, it generally result in a low cardinality score.  
One of the member then reminds us about the selectivity aspect of the data. But my bias again kicked in, assuming that the value of the boolean field would be divided evenly between `true` and `false` value, hence giving a low selectivity score.  
Eventually, I was given a [link to stack overflow](https://stackoverflow.com/questions/10524651/is-there-any-performance-gain-in-indexing-a-boolean-field) that is talking about just this topic. 

tldr; whether or not indexing a boolean field help in optimizing the query is that it depends on your data distribution. Allow me to explain.

## Cardinality and Selectivity
Let's first address the first 2 terms I have mentioned in the first paragraph: Cardinality and Selectivity. 
The cardinality in mathematical refers to the amount of value in a set. Extending the definition to the data, the cardinality of data generally means how many unique values are there in the data set.

# TODO: Selectivity

## Indexing a Boolean Field
Coming back to indexing a boolean field, it would indeed be not very helpful if our boolean data is distributed evenly between the value `true` and `false`. However, if the data of the boolean field is such that it leans heavily towards one or the other, it will not be the case.
Considering 

## Indexing: A book Analogy
There's an excellent analogy from the original stackoverflow comparing the index of database to book index, which I'll put it here with a bit of paraphrasing. But you are highly encouraged to checkout the original answer. 

### A book of `true` and `false`
Imagine that you have a book, and as usual there will be an index page at the end of the book. Additionally, this book of yours consists of 1,000 pages and a big `true` or `false` is written on each of these pages. So, the index of your book will only have 2 entries: true and false. Each of the entries then will have a list of page number on which the value appears in the book. For instance, if on page 1,2,3,5,10 the word `true` is written, the index entry would look like this:

```
true: 1,2,3,5,10
```

Now, if your book is such that only 5 pages out of the 1,000 pages are the "true" page, it would definitely help if you have an index entry to help you keep track of these pages that consists of the true value. 
On the other hand, if 500 pages out of 1,000 pages are the "true" page, your index entry for "true" would swell to such a large size that doing a look up guided by the index is not that efficient. Instead, the sensible strategy would perhaps be to start reading the book from page 1 in order to get all the "true" value.

### Additional Cost in Database
When we come to database, indexing doesn't come free. Firstly, to maintain an index, every write operation will need to update the index. Of course it's not a problem for a write light system. Secondly, the index takes up your storage space. 

## Reference

