# ETAMessages
Class project

- How to test (recommend to do in extended View: ^)

	Mobile Mode:

		- Tap Enable button:
		  Display changes from "- locationManager..." to local coordinates.

		- Update location via simulator menu:
		  Debug -> Location -> CustomLocation:
		  Blue dot will move to new location, mapView will be centered.

		- Tap Disable button:
		  Display is cleared. Local coordinates removed.


	Stationary Mode:

		- Tap Poll button: (this is for test purposes only, will removed)
		  local and remote coordinates are displayed. Remote user is noted
		  with a pointAnnotation (red pin), local user noted with blue dot.

		- Tap Poll button again:
		  eta and distance data is appended to the display. mapView is
		  refreshed, center between users, span'ed appropriately to cover
		  most of mapView.

		- Move local user closer to remote user (backwards but works to
		  test eta notification trigger code) via Simulator:
		  Debug -> Location -> CustomLocation. Changing the 3rd and 4th
		  decimals to match remote coordinates is sufficient to trigger the
		  ETA==0 condition (<50 sec):
		  Local user blue dot moves to red pin. Polling stops. Display
		  notes "Oscar has arrived"

		- Tap Disable button:
		  MapView is refresh showing just the blue dot, and re-spanned.
		
	Known Issues:
		- Reloading the app via the txt-msgs app-store may result in
		  corrupted mapView.
		
		
- How did you organize the project's code and resources?

  - Cloud.swift
    Upload, fetch, save, delete a record to/from iCloud repo.
    
    Post-Review Updates:
    - Update upload() to take in whenDone closure , and to call
      back with result whenDone(result). Call publicDatabase.delete()
      directly in upload(), call publicDatabase.save() in success
      path of publicDatabase.delete() closure.
    - Remove semaphore locks in deleteRecord(). Remove saveRecord().
      Re-implement fetchRecord() to take in a whenDone closure, which
      will be called with a packet argument.
    - Update to use the packet.setLocation() methods.
    - Remove pre-comments code.
    - Re-enable an error print().
    
  - Uploading.swift - New
  	Manage mobile mode behavior, with localUser and single packet
  
    Post-Review Updates:
    - Update uploadLocation() to take in whenDone closure, and to call
      back with result whenDone(result).
    - Remove pre-comments code.
  
  - Users.switf - New
  	Knows user name and location info
  	
  	Post-Review Updates:
    - Create initializer that takes user name and location. Remove separate
      lat/long setters with a single location setter.
    - Remove the name set/getters.
    - Remove pre-comments code.
  	  
  - Poll.swift
    Poll iCloud repo for content changes in remote-User's location record.

    Post-Review Updates:
    - Re-do fetchRemote() to take in a whenDone closure, which is called
      with a packet argument. Update to accomodate optional coordinates.
      Pass a closure to the fetchRemote() call in pollRemote(). Make
      call to eta.getEtaDistance() in closure.
    - Update to use the Location(userName:location) initializer and the
      setLocation() method.
    - Check self.myEta and self.etaOriginal for nil values.
    - Remove pre-comments code.
    - Add support to instantiate PseudoNotificationsViewController on
      ETA == 0.
    - Replace sleep(2) with a DispatchSourceTimer.
    - Cleanup etaNotification(): Create setupLocalNotification() and
      setupPseudoLocalNotification().
    - Fix explicit unwrapping crash in pollRemote().
    - Set self.etaOriginal once myEta is no longer nil.
    - Reduce polling interval to 1700 milli seconds for simulation.
    
  - MapUpdate.swift
    Manage mapView updates for remote-user pin, map centering and spanning, and
    display updates.

    Post-Review Updates:
    - Update to accomodate the to-optional changes in Location.swift
    - Return the larger of the lat/long deltas in centerView(). Use as
      span delta suggestions in refreshMapView(). Cleanup ternary operator use
      to compute latDistTo and longDisto, and center point coordinates. Add
      a few more cases in the refreshMapView() switch.
    - Remove pre-comments code.
    - Update case value for span deltas.
    - Replace delta switch with:  delta = Float(distance * 0.0000015)
  
  - Location.switch
    Location coordinate structure.
    
    Post-Review Updates:
    - Make latitude and longitude optionals.
    - Create constructors that take in userName and Location. Replace
      separate lat/long-setter with a single location setter.
    - Remove pre-comments code.
    
    
  - Eta.swift
    eta value and etaPointer structure.
    moved in getEtaDistance() from MapUpdate.swift
    
    Post-Review Updates:
    - Update getEtaDistance() to update mapView and display within the closure.
    - Note ETA server error: "Directions Not Available"
    - Update print()s.
    - Remove the UnsafeMutableRawPointer.
    - Refresh mapView in case of "Directions Not Available" error in
      mkDirections.calculate().
    - Remove pre-comments code.
    - Add localNotification calls.
    - Set mkDirReq.transportType to .automobile.
    - Track distance vs. eta for simulation.


  - GPSsLocation.swift
  	Manages local and remote location updates when CLLocation Framework
  	calls locationManager()
  	
  	Post-Review Updates:
  	- Update uploadToIcloud() to take in whenDone closure, and to call
      back with result whenDone(result).
    - Update checkRemote() to take in mapView, EtaAdapter, and display
      parameters for use in the pollRemoteUser.fetchRemote() closure.
    - Remove lat/long-setting in init(). Update checkRemote() to take in
      a closure argument result(Bool). Set remoteUser.location directly to
      packet.
    - Update to not call Users.getName().
    - Remove pre-comments code.
    - Change class name to GPSLocationAdapter.
    - Move in handleUploadResult() and handleCheckRemoteResult() from
      MessagesViewController.swift.
 
 
  - ETANotifications.swift - New File
    Configure, register, and schedule local notifications.



  - LocalNotificationDelegate.swift - New file.
    Responding to actionable notifications and receiving notifications
    while your app is in the foreground


  - PseudoNotificationsViewController.swift - New file.
    View holding a UILabel to present a blue background and a "Has Arrived"
    message. Instantiated in PollManager.etaNotification() when ETA == 0
    (or close enough).
    
  - MobilitySimulator.swift - New file.
    Simulate iPhone device mobility by updating iCloud record directly.
    
    - Reduce step increments to 0.0025 when will jump over destination.


  - MessagesViewController.swift
    Manages the UI implemented in IBACtion functions enable() and poll().
    The mobile user enters the app via the Enable button, the stationary
    users does so via the Poll button. Local location changes come in to
    the locationManager() CLLOcation callback function.
    
    A UILabel notes local and remote coordinate data, and eta/distance
    info. At times it reports specific app state, sort of like a console.
    
    Post-Review Updates:
    - Update upload.uploadLocation() call to pass a closure.
      Update gpsLocation.uploadToIcloud() call to pass a closure.
    - Add display argument to gpsLocation.checkRemote() call. Call
      self.pollManager.fetchRemote() with a closure that is called back
      with a packet argument. Call displayUpdate() in main DispatchQueue.
      Move display updates into self.eta.getEtaDistanc() closure.
    - Unwrap locations.last in locationManager(). Set self.localUser.location
      directly to lmPacket per GPSLocation changes. Call
      self.handleUploadResult(result) in self.gpsLocation.uploadToIcloud()
      closure, in locationManager(). Add handleUploadResult() method that
      takes in a closure to process the uploadToIcloud() result, updating
      the display with appropriate messages, and calling gpsLocation.checkRemote()
      if polling had been enabled. Added handleCheckRemoteResult() method that
      takes in a closure to handle the result of the checkRemote() call.
      Call startUpdatingLocation() and enableUploading() in poll() respond to
      stationary user movement during or after polling.
    - Update to use the Location(userName:location) initializer and the
      setLocation() method.
    - Remove pre-comments code.
    - Add viewWillAppear() override. Add delegate for local notifications.
    - Set pollManager.messagesVC property to self to instantiate
      PseudoNotificationsViewController.
    - Change Food button to Simulate add IBAction to mobilitySumulation. Add
      support for mobility-simulation. Remove reseting of poll_enabled.
    - Move out handleUploadResult() and handleCheckRemoteResult() to
      GPSsLocation.swift.
    - Call pollRemote() inside the success path of the fetchRemote() closure,
      right after calling getEtaDistance().
 
 
- What is the project supposed to do?
  In an environment consiting of two mobile devices, the ETAMessages app
  delivers local notification of remote-user's ETA to Stationary device,
  and uploads location data to iCloud from the Mobile-user's device.
  
- What is working?
  All of the above are working as expected. Remote-User location can be
  read from iCloud records, as the devices get closer, the mapView span is
  updated to zoom in. Mobile device location coordinates are updated to
  iCloud repo. ETA and distance data extraction is working.
  
- What is not?
  Can't receive remote or local notifications. This is expected behavior
  for a Messages Extension, will need to incorporate as a target of a
  parent app.
  
- Are there any problems that you know you need to fix?
  
  MapView corruption and missing mapView on some launches.
  
  
- Are there any areas where you would like help?

  Not yet.
  
  
- TODO:
	- Implement local notifications for has-arrived notice.
	- Implement remote notification from iCloud record server.
	- Consider pop-up menu to enable/disable stationary and mobile modes.
	  Or possibly just note if enabled/disabled
	  by changing the button item background?
	  Then Remove the Disable button.
	- Add directions overlay to mapView.

  
