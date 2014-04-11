UAErrorManager
==============

Singelton class for the display of error messages. Requires BlocksKit

It allows you to easily replace the default system messages that are often unclear to users.

Additionally it only permits the display of one UIAlertView per error code so that error's won't get stacked up behind each other.

#Requirements#
[BlocksKit](https://github.com/zwaldowski/BlocksKit) - feel free to replace the UIAlertView code yourself to use the traditional delegate methods but you'll save yourself a lot of time going forward if you start using BlocksKit now.

#Usage#

You can either create your own error or pass a received one:

```
NSError *error = [NSError errorWithDomain:@"com.urbna.demo" code:202 userInfo:
@{ UAErrorManagerErrorMessageDetailedDescriptionKey : @"More info text" } ];

[UAErrorManager showAlertViewForError:error];
```

#To Do#
- Add an option to only display errors with specific codes once
- Add an option to reset the display once limitation
- Add an option to only display errors with specific codes dependant on whether the network is available.
