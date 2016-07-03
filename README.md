# SynEdit-for-Delphi
Delphi - Classes, Documentation and General Tips on the SynEdit suite of components

Having been an avid developer of Delphi since Turbo Pascal II way back in the 80's and a major contributor to the now discontinued "Delphi3000.com", I was impressed with finding the Free Pascal implementation of "SynEdit".

The implementaion code is a great example of self documenting pascal code, but for the uninitiated it suffers seriously from a lack of technical documentation. My purpose on starting this project is that I had a serious problem in a simple requirement of trying to find out how to save and load editor options using the TSynEditOptionsDialog class. Web searches returned unuseful solutions. Eventually digging into the code it became apparent what needed to be done to implement this functionality, but not that obvious to the casual developer and at the least "Programmer Unfriendly" from an IDE property/method dropdown point of view.

NOTE : All of my classes and units are designed for DELPHI only. I know all of the SynEdit objects cater for Cross Platform Compilers, but my platform of choice is MS-Windows. It should however not be a "Train-Smash" for anyone wanting to convert my code to "Multi-Platform" and I am available for queries on any potential problems that arise here. I do not have access to all the available platforms and cannot test and debug, hence the limitation of my examples without conditional compiles for platforms other than Delphi. 

The first Class implemented is TSynEditOptionsConfig which allows editor option editing and save/load as "Black-Box Class" functionality.

Working of class TSynEditKeyUtils which will assist in the processing and getting information about the SynEdit keystrokes.
