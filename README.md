# ETAMessages
Class project

Nuked in the last push. Will need to redo.

- How did you organize the project's code and resources?

  - Cloud.swift
    Upload, fetch, save, delete a record to/from iCloud repo.
    
  - Poll.swift
    Poll iCloud repo for content changes in remote-User's location record.
    
  - MapUpdate.swift
    Manage mapView updates (addPin) and getting ETA and distance between
    local and remote devices/users.
  
  - Location.switch
    Location coordinate structure.
    
  - Eta.switch
    eta value and etaPointer structure.
    
  - MessagesViewController.swift
    Manages the UI implemented in IBACtion functions enable() and poll().
    The mobile user enters the app via the Enable button, the stationary
    users does so via the Poll button. Local location changes come in to
    the locationManager() CLLOcation callback function.
    
    A UILabel notes local and remote coordinate data, and eta/distance
    info. At times it reports specific app state, sort of like a console.
 
- What is the project supposed to do?
  In an environment consiting of two mobile devices, the ETAMessages app
  delivers local notification of remote-user's ETA to Stationary device,
  and uploads location data to iCloud from the Mobile-user's device.
  
- What is working?
  All of the above are working as expected. Remote-User location can be
  read from iCloud records, as the devices get closer, the mapView span is
  updated to zoom in. Mobile device location coordinates are updated to
  iCloud repo. ETA and distance data extraction is working. The polling
  for remore-location code is in, but needs some refinements. A while loop
  is launched in a separate thread, but need to add loop termination code.
  The etaNotifications() method exits but need refinement. Need to create
  an appropriate function to translate distance to mapView span.
  
- What is not?
  Getting random app crashes, likely assocciated with the use of an
  UnsafeMutableRawPointer (for eta data storage in completionhandled
  closures). Getting better, but not yet cleared.
  
- What should a reviewer do in order to test your project?
  Location coordinates can be updated in the simulator via Debug->Location.
  Depending on the app mode (mobile/stationary) Debug->Location will move
  the blue dot or the red pin.
  
- Are there any problems that you know you need to fix?
  Yes, the random crashes mentioned above.
  
- Are there any areas where you would like help?
  Not yet. Got good input/suggestions from Michael in 1st code submittion, will work on them.
  
