# Tom Christiansen's perl version of the grep utility

### General

This repository is based on the original version of `tcgrep` that was introduced in the "Perl Cookbook". It is a rewrite in Perl of `grep` and offers these additional features:

* Runs on every computer where Perl is installed
* Automatically expands zipped files
* Searches recursively in directories

To search recursively for `PATTERN` in your `Projects` folder, run the command below. This also searches in zipped files.

```
    tcgrep -r 'PATTERN' ~/Projects
```

The latest release of `tcgrep` is v1.7. For those interested in history, earlier versions have also been committed here.

### My changes

I added these patches to `tcgrep` in this repository:

* Support globbing for Windows
* Changes for uncompressing

This makes `tcgrep` more comfortable to use on modern computers.
