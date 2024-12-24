---
title: "Git Objects Permissions"
date: 2022-11-16T10:50:39+08:00
draft: false
summary: In this article, we'll look at how Git is handling the file mode of each files we've checked in.
---
## Overview
In this article, we'll look at how Git is handling the file mode of each file we've checked in.

## File Mode In Linux
In Linux, each file has a file mode attribute. The file mode dictates the accessibility permission of the files for every user in the system. 
Let's take a look at an example of the file mode of the file *script.sh* using the *ls -l* command:
```bash
$ ls -l
total 0
-rwxr--r-- 1 bob bob 0 Nov 12 03:16 script.sh
```

The first column of the output is the file mode for our *script.sh* file. 

The file mode has 9 different bits that control the permission of a given file. If a particular permission is granted, the bit will be set and will be displayed with the characters `r` (readable), `w` (writable), and `x` (executable) depending on the permission granted. 

On the other hand, if the bit is unset (which means permission is not granted), it will be displayed as with the `-`, which is a hyphen character.

Generally, we can express the file mode as such:

```
      [owner]            [group of owner]        [everyone]
[read][write][execute][read][write][execute][read][write][execute]
```



With the file mode of *script.sh* being *-rwxr--r--*, we can interpret it as:
- readable, writable, and executable by the owner of the file, which is user bob in this case
- readable only by everyone in the same group as bob
- readable only by everyone else in the system

### File Mode As Decimal
File mode is commonly referred to in its decimal form. In its decimal form, the permissions are expressed as a combination of 3 different 3 bits of numbers. 

For instance, in our previous example, the *script.sh* file mode in binary form is:
```
[111][100][100]
```
When converted to decimal form, it is `744`. 

Note that it's important to grasp this point right as most tools (such as *chmod*) in Linux that deals with permission accept permissions parameters in their decimal format. 

## How Does Git Keep Permission of Files
From [Git's documentation](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects), it only has 3 different file modes for all the files checked in: 
- 100644 - a normal file
- 100755 - an executable file
- 120000 - a symbolic link 

The implication is that the permission for each group of users will be discarded when it's tracked by Git. For instance, when we set a file to be executable by everyone on the system (essentially a `777` permission), Git will track the permission of that file as `755`.

### Git File Mode In Action
Let's take our *script.sh* with file mode `744` and check it into a Git repository:

```bash
$ git init
$ git add script.sh 
$ git commit -m "init"
```

Notice the file permissions will not be changed in our local copy. Re-running the *ls -l* command would give us the same output:

```bash
total 0
-rwxr--r-- 1 bob bob 0 Nov 16 03:21 script.sh
```

Now, let's see how Git is keeping the file permission of the *script.sh*:

```bash
git ls-files --stage
100755 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0       script.sh
```

Notice that the file permission is now `100755`. In other words, our file permission has changed from `744` to `755`

## Why Can't Git Store Permission Bits For Different Group Of Users?

A long time ago, Git used to track the exact file mode of all the files checked in. However, they were removed because it is noisy as the tracked changes are now littered with file mode changes made by different committer. 
The reference is taken from [this Reddit comment](https://www.reddit.com/r/git/comments/cc7tin/comment/etlgcux/?utm_source=share&utm_medium=web2x&context=3) but here's the verbatim copy to prevent deadlinks:
> It only stores the executable bit, and this is a deliberate design choice as explained by Junio Hamano, Git's long-time maintainer in this email thread from December 2008:
> 
>> Why not preserve permissions the way you find them, instead of just using 644 and 755? It certainly couldn't be more complicated than what you are doing now, and that way one could do things like use git to update system administration files across a sneakernet containing e.g.,
> 
>>> \# dlocate -lsconf exim4-config|sed 's/ .*//'|sort -u
>>> 
>>> -rw-r-----
>>> -rw-r--r--
>>> -rwxr-xr-x
>>> 
>> Actually in a very early days, git used to record the full (mode & 0777) for blobs.
>>
>> Once people started using git, everybody realized that it had a very unpleasant side effect that the resulting tree depended on user's umasks, because one person records a blob with mode 664 and the next person who modifies the file would record with mode 644, and it made it very hard to keep track of meaningful changes to the source code. This issue was fixed long time ago with commit e447947 (Be much more liberal about the file mode bits., 2005-04-16).

## Summary
In Linux, we have file mode that restricts the permissions to a file for a different group of users. When they are checked into Git, only the executable bit is tracked and the rest of the owner and group bits are discarded.