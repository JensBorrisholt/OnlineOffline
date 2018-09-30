# OnlineOffline
Delphi unit to check Online state

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
