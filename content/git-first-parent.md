Title: What Does --first-parent Flag in Git Show Do?
Date: 2020-10-30 10:30
Category: Article
Categories: git
Tags: git, log, first-parent, merge-commit
Authors: Chin Ming Jun

[`git show`](https://git-scm.com/docs/git-show) is a command-line tool that allows us to quickly glance through the details of a specific commit, in particular the changes in that commit.

## A Simple Repository
To ease our explanation, let's create a simple repository. 

In this repository, we are creating a dummy app that contains three different modules: `server.py`, `dashboard.py`, and `notification.py`. We are going to commit in a specific manner such that we can build a history that is worth examining.

### Commit Pattern
We'll first commit `server.py` and `dashboard.py` into the master branch directly. 
```bash
* 1166bbc (HEAD -> master) Built dashboard.py
* a150c9f Created server.py
```
Then, we'll simulate a normal git workflow that branches off a feature branch (`notification-module`) to build the `notification.py`. 
```bash
* 433068b (HEAD -> notification-module) Built notification.py
* 1166bbc (master) Built dashboard.py
* a150c9f Created server.py
```
Before the `notification.py` is merged back into the `master` branch, there's a commit on the `master` branch that introduces an `urgent_fix.py`. 
```bash
* ea58347 (HEAD -> master) Urgent Fix on master branch
| * 433068b (notification-module) Built notification.py
|/  
* 1166bbc Built dashboard.py
* a150c9f Created server.py
```
Finally, we merge the `notification-module` branch into the `master` branch, resulting in the following history line:
```bash
*   0225f9e (HEAD -> master) Merge branch 'notification-module'
|\  
| * 433068b (notification-module) Built notification.py
* | ea58347 Urgent Fix on master branch
|/  
* 1166bbc Built dashboard.py
* a150c9f Created server.py
```

## `git show` on a Normal Commit
When we run `git show` on a normal commit, we can safely expect that the output will contain the details of that commit such as authors, commit date, and commit message. What's interesting is that it will also display the changes that are introduced in this commit.  

Let's run `git show` on the second commit in our toy example. 
```bash
$ git show 1166bbc --name-status
commit 1166bbc5d066f0949cc778aff471c9f02fcfc270
Author: Chin Ming Jun <mjchi7.misc@gmail.com>
Date:   Fri Oct 30 10:48:45 2020 +0800

    Built dashboard.py

A       dashboard.py
```
As expected, `git show` basically *show* us the commit as instructed, including the commit SHA, author's name and email, date, and the commit message.  

Additionally, in the last section, **`git show` also tells us the changes that are being introduced in this commit**. Concretely, it shows us that what's changed in the commit `1166bbc` is that the file `dashboard.py` is being (A)dded.  

### How Can `git show` Tell The Changes?
To know what are the changes introduced in this commit, `git show` will compare the files in the commit against the parent's commit files.

When we do a `git show` on commit `1166bbc`, it is ["diff"-ing](https://git-scm.com/docs/git-diff) that commit against its parent's commit. Since the file `dashboard.py` doesn't exist in the parent commit (`a150c9f`), therefore it can be concluded that it is being added in commit `1166bbc`.

## `git show` on a Merge Commit
Before we go any further, let's take a second to understand the difference between merge commits and normal commits
### What Makes a Commit "Merge Commit"
In git, **a merge commit is a commit that has at least two parents**. For a commit to have more than one parent, it has to undergo the `git merge` process. If we take a look at our commit `0225f9e`, we can see that it has two arrows pointing to the tip of the `notification-module` branch, and the commit `0225f9e`. That's because the commit `0225f9e` is the result of merging between the `notification-module` branch and the commit `0225f9e`. 

### Which Parent Would `git show` "diff" Against In a Merge Commit?
If you are following the article so far, one question would immediately pop up at this point: against which parent will the command `git show` diff against in a merge commit, in which there are at least two parents?  
The answer, by default, is **all of the parents**.  
Let's verify our claim by running the `git show` command on the commit `0225f9e`
```bash
$ git show 0225f9e --name-status
commit 0225f9e792abfb558e10584d08dcd4105f3180ce
Merge: ea58347 433068b
Author: Chin Ming Jun <mingjun.chin@thetasp.com>
Date:   Fri Oct 30 10:50:27 2020 +0800

    Merge branch 'notification-module'

```
But something isn't right here: **the output says there are no changes in this commit**!  

To understand why, we'll need to know that when we say `git show` is comparing the commit against all of the parents, what that essentially means is that **it'll compare the commit against each parent, take the results, and find the intersecting changes**.  

If we put it in a Venn diagram, it will look something like this:  

<div style="text-align:center"><img src="{attach}images/git-first-parent/git-first-parent-changes-intersection.png"/></div>  

If we are comparing the files of the merged commit against the urgent fix commit (`ea58347`), we know that the difference is the addition of the `notification.py` file. However, if we are now comparing the files of the merge commit against the `notification-module` branch (`433068b`), the changes would be the addition of the file `urgent_fix.py`.  

Since both of them do not share a similar set of changes, the `git show` simply shows there are no changes.

## The First Parent In Git
The first parent is an important concept in git, especially in the context of the merge commit. As we've mentioned previously, merge commit have at least two parents. Out of these parents in the merge commit, the first parent is usually the one of interest.  

**The first parent of a merge commit is referring to the branch that is checked out when the merge happens**. In our case, the first parent of our merge commit is referring to the commit that adds the `urgent_fix.py` since we are on the `master` branch when the merge happens.

## Running `git show` with the flag `--first-parent`
Let's now go back to our example of running `git show` on the merge commit. If we think about it, what we wanted to know is actually (in plain English): "What changes does the merge brought into my `master` branch?". Translated to `git` terminology, it would mean that we wanted `git show` to tell us the difference between the merge commit, against the first parent. 

Conveniently, the `git show` command has a flag that does just that:
```bash
git show 0225f9e --name-status --first-parent
commit 0225f9e792abfb558e10584d08dcd4105f3180ce (HEAD -> master)
Merge: ea58347 433068b
Author: Chin Ming Jun <mingjun.chin@thetasp.com>
Date:   Fri Oct 30 10:50:27 2020 +0800

    Merge branch 'notification-module'

A       notification.py
```

As we can see from the output, by specifying the `--first-parent` flag, `git show` display the changes of merge commit against the first parent, ea58347.

## Summary
`git show` is a tool that allows us to quickly get the details of a particular commit, especially the changes introduced in that commit against its parent. 

However, with the merge commit, `git show` will just report the set of changes against all the parents, which is usually not our intention. To rectify the behavior, we can simply use the `--first-parent` flag to instruct `git show` to display the changes by comparing against the first parent only.

## References:
https://stackoverflow.com/a/40986893/9897617