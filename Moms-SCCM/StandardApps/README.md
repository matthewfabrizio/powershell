This directory would contain executables that are pretty standard. Unfortunately, at this point in time, there is no real good automation for this (i.e. you can't just dump any .exe or .msi file in this directory and expect it to install).

Maybe at some point in the future a mapping of exe to switches can be made in a file to handle based on application, but to be honest, you should be pushing these via GPO anyway.

This issue stems from the fact that (espcially with .exe) different command line switches are used for almost every application, unless it's an MSI.

If you want to add executables, you either need to make sure the name of them matches what is in the script (i.e. a Firefox exe needs to be called Firefox63.exe and inside the script it needs to be changed in the `Install-Firefox` function).

## A Solution

In case you're wondering what a possible solution may be, I'll throw in my two cents. Maybe if a hash table is setup, a general mapping of common applications and their switches can be manufactured. Example below:

```ps
AppExt = @{
    Firefox = 'ms'
    Acrobat = 'sAll'
}
```

Personally, I don't really think it's worth the time to do this because as I mentioned above, you might as well push standard apps via GPO to all users or to specific OUs.