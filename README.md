# OnlineOffline
Delphi unit to check Online state

## Minimum version  
of Delphi needed: XE8  
But you can alter one line to run under XE7 too. See [here...](https://github.com/JensBorrisholt/OnlineOffline/issues/2#issuecomment-1133890562)  
  
## Installation
Just copy `System.MulticastEventU.pas` to anywhere and add it to your project.  
There is a demo to see, how it can be used. The main part is in `OnlineOfflineU.pas` which is using Indy10 to check google.com.  
  
## Credit

In this solution you'll find a Multicast Event class.
"All Creditc to ALLEN, and his blogpost Multicast events using generics". This is mainly his code. There have only been added support for 64 bit.

### Features
* Checks the connection to the Internet every X seconds
* When online state changed, event are send out to multible listeners with the new state.

### Techniques

In this solution, different techniques have been Implemented.

* Singleton patteren 
* Multicast Events
* Garbage collection, autumatic cleanup of the global instance of TOnlineOffline
* Class decstructor 
* Use of TTask

### Demo

The demo application fills your screen with small boxes (forms) and colors them Gereen or Red for Online and Onnline. The demo application also shows how to force a new  shate, and how to change the ScanningInterval.

![Program Demo](https://raw.githubusercontent.com/JensBorrisholt/OnlineOffline/master/Capture.PNG)
