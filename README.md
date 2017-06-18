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
		- Can't restart polling after Disable or Has-Arrived notification.
		- Reloading the app via the txt-msgs app-store produces strange
		  images on the simulator.
		
		
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
    
  - Uploading.swift - New
  	Manage mobile mode behavior, with localUser and single packet
  
    Post-Review Updates:
    - Update uploadLocation() to take in whenDone closure, and to call
      back with result whenDone(result).
  
  - Users.switf - New
  	Knows user name and location info
  	
  	- replace set/getname() with set/getName().
  	  
  - Poll.swift
    Poll iCloud repo for content changes in remote-User's location record.

    Post-Review Updates:
    - Re-do fetchRemote() to take in a whenDone closure, which is called
      with a packet argument. Update to accomodate optional coordinates.
      Pass a closure to the fetchRemote() call in pollRemote(). Make
      call to eta.getEtaDistance() in closure.
    
  - MapUpdate.swift
    Manage mapView updates for remote-user pin, map centering and spanning, and
    display updates.

    Post-Review Updates:
    - Update to accomodate the to-optional changes in Location.swift
  
  - Location.switch
    Location coordinate structure.
    
    Post-Review Updates:
    - Make latitude and longitude optionals.
    
    
  - Eta.swift
    eta value and etaPointer structure.
    moved in getEtaDistance() from MapUpdate.swift
    
    Post-Review Updates:
    - Update getEtaDistance() to update mapView and display within the closure.
    - Note ETA server error: "Directions Not Available"
    - Update print()s.


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
  is launched in a separate thread, will switch to GCS.
  The etaNotifications() method exits but needs refinement. Need to create
  an appropriate function to translate distance to mapView span.
  
- What is not?
  All implemented code is working.
  
- What should a reviewer do in order to test your project?

  Location coordinates can be updated in the simulator via Debug->Location.
  Depending on the app mode (mobile/stationary) Debug->Location will move
  the blue dot or the red pin.
  
  
- Are there any problems that you know you need to fix?
  
  Remote all semaphore locks, per review comments.
  
  
- Are there any areas where you would like help?

  Not yet. Working on incorporating review comments.
  
  
- TODO:
	- sleep -> NStimer: wait for next class. Will use iCloud container
	  record-change notifications vs. polling.
	- Implement thread synchronization with conditional-vars/mutexes.
	- Implement local notifications.
	- Consider pop-up menu to enable/disable stationary and mobile modes.
	  Or possibly just note if enabled/disabled
	  by changing the button item background? :-)
	  Then Remove the Disable button.
	- Add directions overlay to mapView.
  	- Implement Class Diagram classes:
  		- EtaNotifications
  	- Remove all semaphores per Phil's review comments.
  	- Refactor code to not make sequential calls to closure-invoking
  	  methods, per review comments.
  
